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
    service_type = db.Column(db.String(50), nullable=False)
    description = db.Column(db.Text)
    cost = db.Column(db.Float, nullable=False)
    service_date = db.Column(db.DateTime, nullable=False)
    mileage = db.Column(db.Integer)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
