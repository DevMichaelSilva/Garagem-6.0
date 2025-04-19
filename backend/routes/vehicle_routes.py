from flask import Blueprint, request, jsonify, current_app
from extensions import db
from models import Vehicle, User, Maintenance, MaintenanceImage
from datetime import datetime
import logging
from .auth_routes import firebase_token_required
# Importar funções auxiliares de maintenance_routes (ou duplicá-las se preferir isolamento)
from .maintenance_routes import delete_image_from_storage
from .utils import check_limits # Importar check_limits
import traceback # Para logar stack trace completo

# Configurar logging
logging.basicConfig(level=logging.INFO) # Ajuste o nível conforme necessário
logger = logging.getLogger(__name__)

vehicle_bp = Blueprint('vehicle', __name__)

@vehicle_bp.route('/', methods=['GET'])
@firebase_token_required
def get_vehicles(firebase_uid):
    user = User.query.filter_by(firebase_uid=firebase_uid).first()
    if not user:
        return jsonify({'message': 'Usuário local não encontrado para o token fornecido'}), 404

    vehicles = Vehicle.query.filter_by(user_id=user.id).all()
    
    output = []
    for vehicle in vehicles:
        vehicle_data = {
            'id': vehicle.id,
            'type': vehicle.type,
            'brand': vehicle.brand,
            'model': vehicle.model,
            'year': vehicle.year,
            'license_plate': vehicle.license_plate,
            'color': vehicle.color
        }
        output.append(vehicle_data)
    
    return jsonify({'vehicles': output}), 200

@vehicle_bp.route('/<int:vehicle_id>', methods=['GET'])
@firebase_token_required
def get_vehicle(firebase_uid, vehicle_id):
    user = User.query.filter_by(firebase_uid=firebase_uid).first()
    if not user:
        return jsonify({'message': 'Usuário local não encontrado'}), 404

    vehicle = Vehicle.query.filter_by(id=vehicle_id, user_id=user.id).first()
    if not vehicle:
        return jsonify({'message': 'Veículo não encontrado ou não pertence a este usuário'}), 404

    vehicle_data = {
        'id': vehicle.id,
        'type': vehicle.type,
        'brand': vehicle.brand,
        'model': vehicle.model,
        'year': vehicle.year,
        'license_plate': vehicle.license_plate,
        'color': vehicle.color
    }

    return jsonify(vehicle_data), 200

@vehicle_bp.route('/', methods=['POST'])
@firebase_token_required
def add_vehicle(firebase_uid):
    user = User.query.filter_by(firebase_uid=firebase_uid).first()
    if not user:
        return jsonify({'message': 'Usuário local não encontrado'}), 404

    # --- Verificação de Limite ---
    if not check_limits(user, 'add_vehicle'):
        logger.warning(f"Usuário {user.id} (Tier: {user.tier}) atingiu o limite de veículos.")
        return jsonify({'message': f'Limite de veículos atingido para o plano {user.tier}.'}), 403
    # ---------------------------

    data = request.get_json()
    
    # Verifica se os campos obrigatórios estão presentes
    required_fields = ['type', 'brand', 'model', 'year', 'license_plate']
    for field in required_fields:
        if field not in data:
            return jsonify({'message': f'Campo {field} é obrigatório'}), 400
    
    # Verifica se o tipo de veículo é válido
    valid_types = ['carro', 'moto', 'caminhao']
    if data['type'] not in valid_types:
        return jsonify({'message': 'Tipo de veículo inválido'}), 400
    
    # Cria o novo veículo
    new_vehicle = Vehicle(
        user_id=user.id,
        type=data['type'],
        brand=data['brand'],
        model=data['model'],
        year=data['year'],
        license_plate=data['license_plate'],
        color=data.get('color')
    )
    
    try: # Adicionar try/except para commit
        db.session.add(new_vehicle)
        db.session.commit()
        logger.info(f"Veículo adicionado com sucesso para o usuário {user.id}.")
        return jsonify({
            'message': 'Veículo adicionado com sucesso',
            'vehicle': {
                'id': new_vehicle.id,
                'type': new_vehicle.type,
                'brand': new_vehicle.brand,
                'model': new_vehicle.model,
                'year': new_vehicle.year,
                'license_plate': new_vehicle.license_plate,
                'color': new_vehicle.color
            }
        }), 201
    except Exception as e:
        db.session.rollback()
        logger.error(f"Erro ao salvar novo veículo para usuário {user.id}: {e}")
        return jsonify({'message': f'Erro interno ao salvar veículo: {str(e)}'}), 500

@vehicle_bp.route('/<int:vehicle_id>', methods=['DELETE'])
@firebase_token_required
def delete_vehicle(firebase_uid, vehicle_id):
    user = User.query.filter_by(firebase_uid=firebase_uid).first()
    if not user:
        return jsonify({'message': 'Usuário local não encontrado'}), 404

    try:
        vehicle = Vehicle.query.get(vehicle_id)
        if not vehicle:
            return jsonify({'message': 'Veículo não encontrado'}), 404

        if vehicle.user_id != user.id:
            return jsonify({'message': 'Este veículo não pertence ao usuário atual'}), 403

        # --- Início: Coletar URLs das imagens ANTES de deletar ---
        all_image_urls_to_delete = []
        num_photos_deleted = 0 # Contador
        logger.info(f"Coletando URLs de imagens para exclusão do veículo ID {vehicle_id}...")
        for maintenance in vehicle.maintenances:
            logger.debug(f"  - Verificando manutenção ID {maintenance.id}")
            for image in maintenance.images:
                all_image_urls_to_delete.append(image.image_url)
                num_photos_deleted += 1 # Incrementar contador
                logger.debug(f"    - Coletada URL: {image.image_url}")
        logger.info(f"Total de {len(all_image_urls_to_delete)} URLs coletadas para o veículo ID {vehicle_id}.")
        # --- Fim: Coletar URLs ---

        # Excluir o veículo do banco de dados
        # O cascade='all, delete-orphan' removerá as manutenções e MaintenanceImages associadas
        db.session.delete(vehicle)

        # --- Atualizar contagem de fotos do usuário ---
        if num_photos_deleted > 0:
            user.photo_count = max(0, user.photo_count - num_photos_deleted) # Garante que não seja negativo
            logger.info(f"Contagem de fotos do usuário {user.id} atualizada para {user.photo_count} após excluir veículo {vehicle_id}.")
        # ---------------------------------------------

        db.session.commit() # Commit após deletar veículo e atualizar contagem
        logger.info(f"Veículo ID {vehicle_id} e dados associados excluídos do DB com sucesso.")

        # --- Início: Deletar imagens do Storage APÓS commit do DB ---
        storage_deletion_failed_count = 0
        if all_image_urls_to_delete:
            logger.info(f"Iniciando exclusão de {len(all_image_urls_to_delete)} imagens do Storage para veículo ID {vehicle_id}...")
            for url in all_image_urls_to_delete:
                logger.debug(f"  - Processando URL para exclusão do Storage: {url}")
                if not delete_image_from_storage(url):
                    storage_deletion_failed_count += 1
            if storage_deletion_failed_count > 0:
                 logger.warning(f"{storage_deletion_failed_count} falha(s) ao deletar imagens do Storage para o veículo ID {vehicle_id}. Verifique logs anteriores.")
            else:
                 logger.info(f"Todas as {len(all_image_urls_to_delete)} imagens associadas ao veículo ID {vehicle_id} foram processadas para exclusão do Storage.")
        else:
            logger.info(f"Nenhuma imagem associada encontrada no DB para exclusão do Storage para o veículo ID {vehicle_id}.")
        # --- Fim: Deletar imagens do Storage ---

        return jsonify({'message': 'Veículo e dados associados excluídos com sucesso'}), 200

    except Exception as e:
        db.session.rollback()
        logger.error(f"Erro GERAL ao excluir veículo ID {vehicle_id}: {str(e)}")
        logger.error(traceback.format_exc()) # Log completo do erro
        return jsonify({'message': f'Erro interno ao excluir veículo: {str(e)}'}), 500