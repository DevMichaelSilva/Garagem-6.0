from flask import Blueprint, request, jsonify, current_app
from extensions import db
from models import Maintenance, MaintenanceImage, Vehicle, User
import jwt
from functools import wraps
from datetime import datetime

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
    """
    Retorna todas as manutenções de um veículo específico.
    Os resultados são ordenados por data de serviço em ordem decrescente (mais recentes primeiro).
    """
    # Verificar se o veículo pertence ao usuário
    vehicle = Vehicle.query.filter_by(id=vehicle_id, user_id=current_user.id).first()
    if not vehicle:
        return jsonify({'message': 'Veículo não encontrado ou não pertence a este usuário'}), 404
    
    # Buscar todas as manutenções deste veículo, ordenadas por data (mais recente primeiro)
    maintenances = Maintenance.query.filter_by(vehicle_id=vehicle_id).order_by(Maintenance.service_date.desc()).all()
    
    output = []
    for maintenance in maintenances:
        # Obter as imagens relacionadas a esta manutenção
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
@token_required
def add_maintenance(current_user):
    """
    Adiciona uma nova manutenção para um veículo.
    Campos obrigatórios: vehicle_id, service_type, workshop
    """
    data = request.get_json()
    
    # Verificar se os campos obrigatórios estão presentes
    if not data or not data.get('vehicle_id') or not data.get('service_type') or not data.get('workshop'):
        return jsonify({'message': 'Campos obrigatórios não fornecidos'}), 400
    
    # Verificar se o veículo pertence ao usuário atual
    vehicle = Vehicle.query.filter_by(id=data['vehicle_id'], user_id=current_user.id).first()
    if not vehicle:
        return jsonify({'message': 'Veículo não encontrado ou não pertence a este usuário'}), 404
    
    # Criar nova manutenção
    try:
        # Processar a data do serviço, se fornecida, ou usar a data/hora atual
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
        db.session.flush()  # Para obter o ID antes do commit final
        
        # Adicionar imagens se fornecidas
        if data.get('images'):
            for image_url in data['images']:
                new_image = MaintenanceImage(
                    maintenance_id=new_maintenance.id,
                    image_url=image_url
                )
                db.session.add(new_image)
        
        db.session.commit()
        
        # Preparar a resposta
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
@token_required
def delete_maintenance(current_user, maintenance_id):
    """
    Exclui uma manutenção específica.
    Verifica se a manutenção pertence a um veículo do usuário atual.
    """
    # Buscar a manutenção
    maintenance = Maintenance.query.get(maintenance_id)
    if not maintenance:
        return jsonify({'message': 'Manutenção não encontrada'}), 404
    
    # Verificar se o veículo pertence ao usuário
    vehicle = Vehicle.query.filter_by(id=maintenance.vehicle_id, user_id=current_user.id).first()
    if not vehicle:
        return jsonify({'message': 'Veículo não pertence a este usuário'}), 403
    
    try:
        # Excluir a manutenção e suas imagens (cascade)
        db.session.delete(maintenance)
        db.session.commit()
        
        return jsonify({'message': 'Manutenção excluída com sucesso'}), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'message': f'Erro ao excluir manutenção: {str(e)}'}), 500

@maintenance_bp.route('/<int:maintenance_id>', methods=['GET'])
@token_required
def get_maintenance_details(current_user, maintenance_id):
    """
    Retorna os detalhes de uma manutenção específica.
    Verifica se a manutenção pertence a um veículo do usuário atual.
    """
    # Buscar a manutenção
    maintenance = Maintenance.query.get(maintenance_id)
    if not maintenance:
        return jsonify({'message': 'Manutenção não encontrada'}), 404
    
    # Verificar se o veículo pertence ao usuário
    vehicle = Vehicle.query.filter_by(id=maintenance.vehicle_id, user_id=current_user.id).first()
    if not vehicle:
        return jsonify({'message': 'Veículo não pertence a este usuário'}), 403
    
    # Obter as imagens relacionadas a esta manutenção
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
@token_required
def update_maintenance(current_user, maintenance_id):
    """
    Atualiza os dados de uma manutenção existente.
    Verifica se a manutenção pertence a um veículo do usuário atual.
    """
    data = request.get_json()
    
    # Buscar a manutenção
    maintenance = Maintenance.query.get(maintenance_id)
    if not maintenance:
        return jsonify({'message': 'Manutenção não encontrada'}), 404
    
    # Verificar se o veículo pertence ao usuário
    vehicle = Vehicle.query.filter_by(id=maintenance.vehicle_id, user_id=current_user.id).first()
    if not vehicle:
        return jsonify({'message': 'Veículo não pertence a este usuário'}), 403
    
    try:
        # Atualizar campos (apenas se fornecidos)
        if data.get('service_type'):
            maintenance.service_type = data['service_type']
        if data.get('workshop'):
            maintenance.workshop = data['workshop']
        if 'mechanic' in data:  # Permite enviar vazio
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
        
        # Atualizar imagens se fornecidas
        if 'images' in data:
            # Remover imagens existentes
            MaintenanceImage.query.filter_by(maintenance_id=maintenance.id).delete()
            
            # Adicionar novas imagens
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