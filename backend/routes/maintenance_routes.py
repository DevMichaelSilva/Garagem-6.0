from flask import Blueprint, request, jsonify, current_app
from extensions import db
from models import Maintenance, Vehicle, User
import jwt
from functools import wraps

maintenance_bp = Blueprint('maintenance', __name__)

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

@maintenance_bp.route('/vehicle/<int:vehicle_id>', methods=['GET'])
@token_required
def get_vehicle_maintenances(current_user, vehicle_id):
    vehicle = Vehicle.query.filter_by(id=vehicle_id, user_id=current_user.id).first()
    if not vehicle:
        return jsonify({'message': 'Veículo não encontrado ou não pertence a este usuário'}), 404
    
    maintenances = Maintenance.query.filter_by(vehicle_id=vehicle_id).all()
    
    output = []
    for maintenance in maintenances:
        maintenance_data = {
            'id': maintenance.id,
            'service_type': maintenance.service_type,
            'description': maintenance.description,
            'cost': maintenance.cost,
            'service_date': maintenance.service_date.strftime('%Y-%m-%d'),
            'mileage': maintenance.mileage
        }
        output.append(maintenance_data)
    
    return jsonify({'maintenances': output}), 200

@maintenance_bp.route('/', methods=['GET'])
def get_maintenances():
    # ...existing code...
    pass

@maintenance_bp.route('/<int:maintenance_id>', methods=['GET'])
def get_maintenance(maintenance_id):
    # ...existing code...
    pass

# Endpoint para adicionar manutenção e outras operações serão implementados em uma versão futura