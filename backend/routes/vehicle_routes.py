from flask import Blueprint, request, jsonify, current_app
from extensions import db
from models import Vehicle, User
import jwt
from functools import wraps

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
        except:
            return jsonify({'message': 'Token inválido'}), 401
            
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

# Endpoint para adicionar veículo e outras operações serão implementados em uma versão futura