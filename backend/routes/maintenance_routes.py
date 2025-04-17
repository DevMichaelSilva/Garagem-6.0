from flask import Blueprint, request, jsonify, current_app
from extensions import db
from models import Maintenance, MaintenanceImage, Vehicle, User
from datetime import datetime
from .auth_routes import firebase_token_required

maintenance_bp = Blueprint('maintenance', __name__)

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
        return jsonify({'message': 'Veículo não pertence a este usuário'}), 403

    try:
        db.session.delete(maintenance)
        db.session.commit()
        return jsonify({'message': 'Manutenção excluída com sucesso'}), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'message': f'Erro ao excluir manutenção: {str(e)}'}), 500

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