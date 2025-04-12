from flask import Blueprint, request, jsonify, current_app
from extensions import db
from models import Vehicle, User, Maintenance, MaintenanceImage
import jwt
from functools import wraps
from datetime import datetime
import logging

# Configurar logging
logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)

vehicle_bp = Blueprint('vehicle', __name__)

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

@vehicle_bp.route('/', methods=['GET'])
@token_required
def get_vehicles(current_user):
    vehicles = Vehicle.query.filter_by(user_id=current_user.id).all()
    
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
@token_required
def get_vehicle(current_user, vehicle_id):
    vehicle = Vehicle.query.filter_by(id=vehicle_id, user_id=current_user.id).first()
    if not vehicle:
        return jsonify({'message': 'Veículo não encontrado'}), 404

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
# Adicionar ao arquivo routes/vehicle_routes.py

@vehicle_bp.route('/', methods=['POST'])
@token_required
def add_vehicle(current_user):
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
        user_id=current_user.id,
        type=data['type'],
        brand=data['brand'],
        model=data['model'],
        year=data['year'],
        license_plate=data['license_plate'],
        color=data.get('color')
    )
    
    db.session.add(new_vehicle)
    db.session.commit()
    
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

@vehicle_bp.route('/<int:vehicle_id>', methods=['DELETE'])
@token_required
def delete_vehicle(current_user, vehicle_id):
    """
    Exclui um veículo específico.
    Verifica se o veículo pertence ao usuário atual.
    """
    try:
        # Buscar o veículo
        vehicle = Vehicle.query.get(vehicle_id)
        if not vehicle:
            return jsonify({'message': 'Veículo não encontrado'}), 404
        
        # Verificar se o veículo pertence ao usuário
        if vehicle.user_id != current_user.id:
            return jsonify({'message': 'Este veículo não pertence ao usuário atual'}), 403
        
        # Excluir todas as manutenções relacionadas (as imagens são excluídas em cascata)
        maintenances = Maintenance.query.filter_by(vehicle_id=vehicle_id).all()
        for maintenance in maintenances:
            db.session.delete(maintenance)
        
        # Excluir o veículo
        db.session.delete(vehicle)
        db.session.commit()
        
        logger.info(f"Veículo ID {vehicle_id} excluído com sucesso pelo usuário ID {current_user.id}")
        return jsonify({'message': 'Veículo excluído com sucesso'}), 200
    
    except Exception as e:
        db.session.rollback()
        logger.error(f"Erro ao excluir veículo: {str(e)}")
        return jsonify({'message': f'Erro ao excluir veículo: {str(e)}'}), 500

# Endpoint para adicionar veículo e outras operações serão implementados em uma versão futura