from flask import Blueprint, request, jsonify, current_app, send_from_directory
import os
from extensions import db
from models import MaintenanceImage, Maintenance, User, Vehicle
from utils.image_utils import save_image, delete_image
from functools import wraps
import jwt
import logging
from werkzeug.utils import secure_filename

# Configurar logging
logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)

image_bp = Blueprint('image', __name__)

# Middleware para verificação do token
def token_required(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        token = request.headers.get('Authorization')
        if not token:
            return jsonify({'message': 'Token não fornecido'}), 401
        
        try:
            token = token.split(" ")[1] if len(token.split(" ")) > 1 else token
            data = jwt.decode(token, current_app.config['SECRET_KEY'], algorithms=["HS256"])
            current_user = User.query.get(data['user_id'])
            if not current_user:
                return jsonify({'message': 'Usuário não encontrado'}), 401
        except Exception as e:
            logger.error(f"Erro na autenticação: {str(e)}")
            return jsonify({'message': f'Token inválido: {str(e)}'}), 401
            
        return f(current_user, *args, **kwargs)
    
    return decorated

@image_bp.route('/upload/<int:maintenance_id>/multipart', methods=['POST'])
@token_required
def upload_image_multipart(current_user, maintenance_id):
    """
    Endpoint para upload de imagens multipart para uma manutenção específica
    """
    try:
        logger.debug(f"Iniciando upload multipart para manutenção {maintenance_id}")
        
        # Verificar se a manutenção existe
        maintenance = Maintenance.query.get(maintenance_id)
        if not maintenance:
            logger.warning(f"Manutenção {maintenance_id} não encontrada")
            return jsonify({'message': 'Manutenção não encontrada'}), 404
        
        # Verificar se o veículo pertence ao usuário
        vehicle = Vehicle.query.filter_by(id=maintenance.vehicle_id, user_id=current_user.id).first()
        if not vehicle:
            logger.warning(f"Veículo {maintenance.vehicle_id} não pertence ao usuário {current_user.id}")
            return jsonify({'message': 'Veículo não pertence a este usuário'}), 403
        
        # Verificar se já existem 4 imagens
        image_count = MaintenanceImage.query.filter_by(maintenance_id=maintenance_id).count()
        if image_count >= 4:
            logger.warning(f"Limite de imagens atingido para manutenção {maintenance_id}")
            return jsonify({'message': 'Limite de 4 imagens por manutenção atingido'}), 400
        
        # Verificar se o arquivo está presente
        if 'image' not in request.files:
            logger.warning("Arquivo de imagem não encontrado")
            return jsonify({'message': 'Imagem não enviada'}), 400
            
        file = request.files['image']
        
        if file.filename == '':
            logger.warning("Nome de arquivo vazio")
            return jsonify({'message': 'Nome de arquivo vazio'}), 400
        
        # Verificar extensão
        if not ('.' in file.filename and file.filename.rsplit('.', 1)[1].lower() in ['jpg', 'jpeg', 'png']):
            logger.warning("Extensão de arquivo não permitida")
            return jsonify({'message': 'Formato de arquivo não permitido. Use JPG, JPEG ou PNG'}), 400
        
        # Garantir que a pasta exista
        ensure_upload_folder_exists()
        
        # Gerar nome de arquivo seguro
        filename = secure_filename(f"{uuid.uuid4().hex}_{file.filename}")
        filepath = os.path.join(IMAGE_UPLOAD_FOLDER, filename)
        
        # Salvar arquivo
        file.save(filepath)
        logger.debug(f"Arquivo salvo em {filepath}")
        
        # Criar registro no banco
        image_url = f"/uploads/images/{filename}"
        new_image = MaintenanceImage(
            maintenance_id=maintenance_id,
            image_url=image_url
        )
        db.session.add(new_image)
        db.session.commit()
        
        logger.info(f"Imagem {new_image.id} carregada com sucesso para manutenção {maintenance_id}")
        return jsonify({
            'message': 'Imagem carregada com sucesso',
            'image': {
                'id': new_image.id,
                'url': image_url
            }
        }), 201
        
    except Exception as e:
        db.session.rollback()
        logger.error(f"Erro ao fazer upload de imagem: {str(e)}", exc_info=True)
        return jsonify({'message': f'Erro ao processar imagem: {str(e)}'}), 500

@image_bp.route('/<int:image_id>', methods=['DELETE'])
@token_required
def delete_maintenance_image(current_user, image_id):
    """
    Endpoint para excluir uma imagem específica
    """
    try:
        # Buscar a imagem
        image = MaintenanceImage.query.get(image_id)
        if not image:
            return jsonify({'message': 'Imagem não encontrada'}), 404
        
        # Verificar se a manutenção pertence a um veículo do usuário
        maintenance = Maintenance.query.get(image.maintenance_id)
        if not maintenance:
            return jsonify({'message': 'Manutenção não encontrada'}), 404
        
        # Verificar se o veículo pertence ao usuário
        vehicle = Vehicle.query.filter_by(id=maintenance.vehicle_id, user_id=current_user.id).first()
        if not vehicle:
            return jsonify({'message': 'Veículo não pertence a este usuário'}), 403
        
        # Excluir arquivo físico
        filename = os.path.basename(image.image_url)
        delete_image(filename)
        
        # Excluir registro no banco
        db.session.delete(image)
        db.session.commit()
        
        return jsonify({'message': 'Imagem excluída com sucesso'}), 200
        
    except Exception as e:
        db.session.rollback()
        logger.error(f"Erro ao excluir imagem: {str(e)}")
        return jsonify({'message': f'Erro ao excluir imagem: {str(e)}'}), 500