from flask import Blueprint, request, jsonify, current_app
from extensions import db
from models import Vehicle, User, Maintenance, MaintenanceImage
from datetime import datetime
import logging
from .auth_routes import firebase_token_required

# Configurar logging
logging.basicConfig(level=logging.DEBUG)
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
@firebase_token_required
def delete_vehicle(firebase_uid, vehicle_id):
    user = User.query.filter_by(firebase_uid=firebase_uid).first()
    if not user:
        return jsonify({'message': 'Usuário local não encontrado'}), 404

    try:
        # Buscar o veículo
        vehicle = Vehicle.query.get(vehicle_id)
        if not vehicle:
            return jsonify({'message': 'Veículo não encontrado'}), 404
        
        # Verificar se o veículo pertence ao usuário
        if vehicle.user_id != user.id:
            return jsonify({'message': 'Este veículo não pertence ao usuário atual'}), 403
        
        # Excluir todas as manutenções relacionadas (as imagens são excluídas em cascata)
        maintenances = Maintenance.query.filter_by(vehicle_id=vehicle_id).all()
        for maintenance in maintenances:
            db.session.delete(maintenance)
        
        # Excluir o veículo
        db.session.delete(vehicle)
        db.session.commit()
        
        logger.info(f"Veículo ID {vehicle_id} excluído com sucesso pelo usuário UID {firebase_uid}")
        return jsonify({'message': 'Veículo excluído com sucesso'}), 200
    
    except Exception as e:
        db.session.rollback()
        logger.error(f"Erro ao excluir veículo: {str(e)}")
        return jsonify({'message': f'Erro ao excluir veículo: {str(e)}'}), 500