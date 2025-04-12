from extensions import db
from datetime import datetime

class User(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(80), unique=True, nullable=False)
    email = db.Column(db.String(120), unique=True, nullable=False)
    password_hash = db.Column(db.String(128))
    cpf = db.Column(db.String(14), unique=True, nullable=False)
    phone = db.Column(db.String(20))
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    def __repr__(self):
        return f'<User {self.username}>'

class Vehicle(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)
    type = db.Column(db.String(20), nullable=False)  # carro, moto, caminhão
    brand = db.Column(db.String(50), nullable=False)
    model = db.Column(db.String(50), nullable=False)
    year = db.Column(db.Integer, nullable=False)
    license_plate = db.Column(db.String(15), nullable=False)
    color = db.Column(db.String(30))
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    maintenances = db.relationship('Maintenance', backref='vehicle', lazy=True)

class Maintenance(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    vehicle_id = db.Column(db.Integer, db.ForeignKey('vehicle.id'), nullable=False)
    service_type = db.Column(db.String(100), nullable=False)
    workshop = db.Column(db.String(100), nullable=False)
    mechanic = db.Column(db.String(100))
    labor_warranty_date = db.Column(db.String(20))
    labor_cost = db.Column(db.Float)
    parts = db.Column(db.String(200))
    parts_store = db.Column(db.String(100))
    parts_warranty_date = db.Column(db.String(20))
    parts_cost = db.Column(db.Float)
    service_date = db.Column(db.DateTime, nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    images = db.relationship('MaintenanceImage', backref='maintenance', lazy=True, cascade='all, delete-orphan')

class MaintenanceImage(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    maintenance_id = db.Column(db.Integer, db.ForeignKey('maintenance.id'), nullable=False)
    image_url = db.Column(db.String(255), nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)