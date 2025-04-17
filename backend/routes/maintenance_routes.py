from flask import Blueprint, request, jsonify, current_app
from extensions import db
from models import Maintenance, MaintenanceImage, Vehicle, User
from datetime import datetime
from .auth_routes import firebase_token_required
from firebase_admin import storage # Importar storage
import urllib.parse # Para decodificar URL
import logging # Para logs
import traceback # Para logar stack trace completo

maintenance_bp = Blueprint('maintenance', __name__)
logger = logging.getLogger(__name__) # Configurar logger

# --- Função Auxiliar para Extrair Caminho do Storage ---
def get_storage_path_from_url(image_url):
    """Extrai o caminho do arquivo no Firebase Storage a partir da URL de download."""
    logger.debug(f"Tentando extrair caminho da URL: {image_url}")
    try:
        decoded_url = urllib.parse.unquote(image_url)
        logger.debug(f"URL decodificada: {decoded_url}")
        # Tenta encontrar /o/ que marca o início do caminho do objeto no bucket
        path_start_marker = '/o/'
        path_start_index = decoded_url.find(path_start_marker)

        if path_start_index == -1:
            logger.warning(f"Marcador '/o/' não encontrado na URL decodificada: {decoded_url}")
            return None

        path_start = path_start_index + len(path_start_marker)

        # Tenta encontrar ?alt=media que marca o fim do caminho
        path_end_marker = '?alt=media'
        path_end_index = decoded_url.find(path_end_marker, path_start) # Busca a partir do início do caminho

        if path_end_index == -1:
            logger.warning(f"Marcador '?alt=media' não encontrado após o caminho na URL: {decoded_url}")
            # Considerar que talvez a URL não tenha query parameters? Pouco provável para downloadURL.
            # Se a URL for apenas o caminho, isso pode falhar. Ajustar se necessário.
            # Por enquanto, retorna None se não encontrar o fim esperado.
            return None

        extracted_path = decoded_url[path_start:path_end_index]
        logger.info(f"Caminho extraído do Storage: {extracted_path}")
        return extracted_path

    except Exception as e:
        logger.error(f"Erro EXCEPCIONAL ao extrair caminho da URL {image_url}: {e}")
        logger.error(traceback.format_exc()) # Log completo do erro
        return None

# --- Função Auxiliar para Deletar Imagem do Storage ---
def delete_image_from_storage(image_url):
    """Deleta uma imagem do Firebase Storage usando sua URL."""
    file_path = get_storage_path_from_url(image_url)
    if file_path:
        try:
            bucket = storage.bucket() # Obtém o bucket padrão (verifique se é o correto no Firebase Console)
            logger.info(f"Tentando deletar blob: '{file_path}' do bucket: '{bucket.name}'")
            blob = bucket.blob(file_path)
            blob.delete() # A exclusão em si
            logger.info(f"Blob deletado do Storage com sucesso: {file_path}")
            return True
        except Exception as e:
            # Log detalhado da exceção
            logger.error(f"Falha ao deletar blob '{file_path}' do Storage: {type(e).__name__} - {e}")
            # Verifica se o erro é 'NotFound' (código 404 geralmente)
            # A API Python pode levantar google.cloud.exceptions.NotFound
            from google.cloud.exceptions import NotFound
            if isinstance(e, NotFound):
                 logger.warning(f"Blob não encontrado no Storage (pode já ter sido deletado): {file_path}")
                 return True # Considerar sucesso se não encontrada
            else:
                 # Logar o stack trace para outros erros
                 logger.error(traceback.format_exc())
                 return False # Falha na exclusão por outro motivo
    else:
        logger.error(f"Não foi possível obter o caminho do arquivo para deletar a URL: {image_url}")
        return False # Falha na extração do caminho

@maintenance_bp.route('/vehicle/<int:vehicle_id>', methods=['GET'])
@firebase_token_required
def get_vehicle_maintenances(firebase_uid, vehicle_id):
    user = User.query.filter_by(firebase_uid=firebase_uid).first()
    if not user:
        return jsonify({'message': 'Usuário local não encontrado'}), 404

    vehicle = Vehicle.query.filter_by(id=vehicle_id, user_id=user.id).first()
    if not vehicle:
        return jsonify({'message': 'Veículo não encontrado ou não pertence a este usuário'}), 404

    maintenances = Maintenance.query.filter_by(vehicle_id=vehicle_id).order_by(Maintenance.service_date.desc()).all()
    output = []
    for maintenance in maintenances:
        images = [image.image_url for image in maintenance.images]
        maintenance_data = {
            'id': maintenance.id,
            'service_type': maintenance.service_type,
            'workshop': maintenance.workshop,
            'mechanic': maintenance.mechanic,
            'labor_warranty_date': maintenance.labor_warranty_date,
            'labor_cost': maintenance.labor_cost,
            'parts': maintenance.parts,
            'parts_store': maintenance.parts_store,
            'parts_warranty_date': maintenance.parts_warranty_date,
            'parts_cost': maintenance.parts_cost,
            'service_date': maintenance.service_date.strftime('%Y-%m-%d %H:%M:%S'),
            'created_at': maintenance.created_at.strftime('%Y-%m-%d %H:%M:%S'),
            'images': images
        }
        output.append(maintenance_data)
    return jsonify({'maintenances': output}), 200

@maintenance_bp.route('/add', methods=['POST'])
@firebase_token_required
def add_maintenance(firebase_uid):
    user = User.query.filter_by(firebase_uid=firebase_uid).first()
    if not user:
        return jsonify({'message': 'Usuário local não encontrado'}), 404

    data = request.get_json()
    if not data or not data.get('vehicle_id') or not data.get('service_type') or not data.get('workshop'):
        return jsonify({'message': 'Campos obrigatórios não fornecidos'}), 400

    vehicle = Vehicle.query.filter_by(id=data['vehicle_id'], user_id=user.id).first()
    if not vehicle:
        return jsonify({'message': 'Veículo não encontrado ou não pertence a este usuário'}), 404

    try:
        service_date = datetime.strptime(data.get('service_date', ''), '%Y-%m-%d %H:%M:%S') if data.get('service_date') else datetime.utcnow()

        new_maintenance = Maintenance(
            vehicle_id=data['vehicle_id'],
            service_type=data['service_type'],
            workshop=data['workshop'],
            mechanic=data.get('mechanic'),
            labor_warranty_date=data.get('labor_warranty_date'),
            labor_cost=data.get('labor_cost'),
            parts=data.get('parts'),
            parts_store=data.get('parts_store'),
            parts_warranty_date=data.get('parts_warranty_date'),
            parts_cost=data.get('parts_cost'),
            service_date=service_date
        )

        db.session.add(new_maintenance)
        db.session.flush()

        if data.get('images'):
            for image_url in data['images']:
                new_image = MaintenanceImage(
                    maintenance_id=new_maintenance.id,
                    image_url=image_url
                )
                db.session.add(new_image)

        db.session.commit()

        response_data = {
            'id': new_maintenance.id,
            'vehicle_id': new_maintenance.vehicle_id,
            'service_type': new_maintenance.service_type,
            'workshop': new_maintenance.workshop,
            'mechanic': new_maintenance.mechanic,
            'labor_warranty_date': new_maintenance.labor_warranty_date,
            'labor_cost': new_maintenance.labor_cost,
            'parts': new_maintenance.parts,
            'parts_store': new_maintenance.parts_store,
            'parts_warranty_date': new_maintenance.parts_warranty_date,
            'parts_cost': new_maintenance.parts_cost,
            'service_date': new_maintenance.service_date.strftime('%Y-%m-%d %H:%M:%S'),
            'created_at': new_maintenance.created_at.strftime('%Y-%m-%d %H:%M:%S'),
            'images': data.get('images', [])
        }
        return jsonify({'message': 'Manutenção adicionada com sucesso', 'maintenance': response_data}), 201

    except Exception as e:
        db.session.rollback()
        return jsonify({'message': f'Erro ao adicionar manutenção: {str(e)}'}), 500

@maintenance_bp.route('/<int:maintenance_id>', methods=['DELETE'])
@firebase_token_required
def delete_maintenance(firebase_uid, maintenance_id):
    user = User.query.filter_by(firebase_uid=firebase_uid).first()
    if not user:
        return jsonify({'message': 'Usuário local não encontrado'}), 404

    maintenance = Maintenance.query.get(maintenance_id)
    if not maintenance:
        return jsonify({'message': 'Manutenção não encontrada'}), 404

    vehicle = Vehicle.query.filter_by(id=maintenance.vehicle_id, user_id=user.id).first()
    if not vehicle:
        # Alterado para 403 Forbidden, pois a manutenção existe mas não pertence ao usuário
        return jsonify({'message': 'Manutenção não pertence a um veículo deste usuário'}), 403

    # --- Início: Lógica de exclusão de imagens ---
    image_urls_to_delete = [img.image_url for img in maintenance.images]
    logger.info(f"Iniciando exclusão de {len(image_urls_to_delete)} imagens do Storage para manutenção ID {maintenance_id}")
    storage_deletion_failed = False
    for url in image_urls_to_delete:
        logger.debug(f"Processando URL para exclusão: {url}")
        if not delete_image_from_storage(url):
            storage_deletion_failed = True # Marca se alguma exclusão falhar
    # --- Fim: Lógica de exclusão de imagens ---

    # Prosseguir com a exclusão do banco de dados mesmo se a exclusão do storage falhar?
    # Decisão: Sim, mas logar o erro. A referência no DB será removida.
    if storage_deletion_failed:
        logger.warning(f"Falha ao deletar uma ou mais imagens do Storage para a manutenção ID {maintenance_id}. Verifique os logs.")

    try:
        # Excluir a manutenção (cascade removerá MaintenanceImage do DB)
        db.session.delete(maintenance)
        db.session.commit()
        logger.info(f"Manutenção ID {maintenance_id} excluída do DB com sucesso.")
        return jsonify({'message': 'Manutenção excluída com sucesso'}), 200
    except Exception as e:
        db.session.rollback()
        logger.error(f"Erro ao excluir manutenção ID {maintenance_id} do DB: {e}")
        logger.error(traceback.format_exc()) # Log completo do erro de DB
        return jsonify({'message': f'Erro ao excluir manutenção do banco de dados: {str(e)}'}), 500

@maintenance_bp.route('/<int:maintenance_id>', methods=['GET'])
@firebase_token_required
def get_maintenance_details(firebase_uid, maintenance_id):
    user = User.query.filter_by(firebase_uid=firebase_uid).first()
    if not user:
        return jsonify({'message': 'Usuário local não encontrado'}), 404

    maintenance = Maintenance.query.get(maintenance_id)
    if not maintenance:
        return jsonify({'message': 'Manutenção não encontrada'}), 404

    vehicle = Vehicle.query.filter_by(id=maintenance.vehicle_id, user_id=user.id).first()
    if not vehicle:
        return jsonify({'message': 'Veículo não pertence a este usuário'}), 403

    images = [image.image_url for image in maintenance.images]
    maintenance_data = {
        'id': maintenance.id,
        'vehicle_id': maintenance.vehicle_id,
        'service_type': maintenance.service_type,
        'workshop': maintenance.workshop,
        'mechanic': maintenance.mechanic,
        'labor_warranty_date': maintenance.labor_warranty_date,
        'labor_cost': maintenance.labor_cost,
        'parts': maintenance.parts,
        'parts_store': maintenance.parts_store,
        'parts_warranty_date': maintenance.parts_warranty_date,
        'parts_cost': maintenance.parts_cost,
        'service_date': maintenance.service_date.strftime('%Y-%m-%d %H:%M:%S'),
        'created_at': maintenance.created_at.strftime('%Y-%m-%d %H:%M:%S'),
        'images': images
    }
    return jsonify({'maintenance': maintenance_data}), 200

@maintenance_bp.route('/<int:maintenance_id>', methods=['PUT'])
@firebase_token_required
def update_maintenance(firebase_uid, maintenance_id):
    user = User.query.filter_by(firebase_uid=firebase_uid).first()
    if not user:
        return jsonify({'message': 'Usuário local não encontrado'}), 404

    data = request.get_json()
    maintenance = Maintenance.query.get(maintenance_id)
    if not maintenance:
        return jsonify({'message': 'Manutenção não encontrada'}), 404

    vehicle = Vehicle.query.filter_by(id=maintenance.vehicle_id, user_id=user.id).first()
    if not vehicle:
        return jsonify({'message': 'Veículo não pertence a este usuário'}), 403

    try:
        if data.get('service_type'):
            maintenance.service_type = data['service_type']
        if data.get('workshop'):
            maintenance.workshop = data['workshop']
        if 'mechanic' in data:
            maintenance.mechanic = data['mechanic']
        if 'labor_warranty_date' in data:
            maintenance.labor_warranty_date = data['labor_warranty_date']
        if 'labor_cost' in data:
            maintenance.labor_cost = data['labor_cost']
        if 'parts' in data:
            maintenance.parts = data['parts']
        if 'parts_store' in data:
            maintenance.parts_store = data['parts_store']
        if 'parts_warranty_date' in data:
            maintenance.parts_warranty_date = data['parts_warranty_date']
        if 'parts_cost' in data:
            maintenance.parts_cost = data['parts_cost']
        if data.get('service_date'):
            maintenance.service_date = datetime.strptime(data['service_date'], '%Y-%m-%d %H:%M:%S')

        if 'images' in data:
            MaintenanceImage.query.filter_by(maintenance_id=maintenance.id).delete()
            for image_url in data['images']:
                new_image = MaintenanceImage(
                    maintenance_id=maintenance.id,
                    image_url=image_url
                )
                db.session.add(new_image)

        db.session.commit()
        return jsonify({'message': 'Manutenção atualizada com sucesso'}), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'message': f'Erro ao atualizar manutenção: {str(e)}'}), 500