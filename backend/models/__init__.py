from extensions import db
from datetime import datetime, timedelta # Adicionar timedelta

# --- Constantes de Limites ---
TIER_LIMITS = {
    'Free': {'vehicles': 1, 'services': 3, 'photos': 0},
    'Premium_01': {'vehicles': 1, 'services': float('inf'), 'photos': 40},
    'Premium_03': {'vehicles': 1, 'services': float('inf'), 'photos': 120},
    'Premium_05': {'vehicles': 1, 'services': float('inf'), 'photos': 200},
    'Premium_10': {'vehicles': 1, 'services': float('inf'), 'photos': 400},
}
# -----------------------------

class User(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    firebase_uid = db.Column(db.String(128), unique=True, nullable=False)
    username = db.Column(db.String(80), nullable=False)
    email = db.Column(db.String(120), unique=True, nullable=False)
    cpf = db.Column(db.String(14), unique=True, nullable=True)
    phone = db.Column(db.String(20), nullable=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    vehicles = db.relationship('Vehicle', backref='owner', lazy=True, cascade='all, delete-orphan') # Cascade adicionado para consistência

    # --- Novos Campos ---
    tier = db.Column(db.String(20), nullable=False, default='Free') # Nível do usuário
    subscription_end_date = db.Column(db.DateTime, nullable=True) # Data de expiração da assinatura
    photo_count = db.Column(db.Integer, nullable=False, default=0) # Contagem de fotos do usuário
    is_admin = db.Column(db.Boolean, nullable=False, default=False) # Flag de administrador
    # Relacionamento com UserCouponUsage
    coupon_usages = db.relationship('UserCouponUsage', backref='user', lazy=True, cascade='all, delete-orphan')
    # --------------------

    def __repr__(self):
        return f'<User {self.username} (Tier: {self.tier})>'

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
    maintenances = db.relationship('Maintenance', backref='vehicle', lazy=True, cascade='all, delete-orphan')

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

# --- Novos Modelos ---
class Coupon(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    code = db.Column(db.String(50), unique=True, nullable=False, index=True)
    value_days = db.Column(db.Integer, nullable=False) # Dias adicionados à assinatura
    is_active = db.Column(db.Boolean, nullable=False, default=True)
    usage_count = db.Column(db.Integer, nullable=False, default=0) # Contagem total de usos
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    # Relacionamento com UserCouponUsage
    user_usages = db.relationship('UserCouponUsage', backref='coupon', lazy=True, cascade='all, delete-orphan')

    def __repr__(self):
        return f'<Coupon {self.code} ({self.value_days} days)>'

class UserCouponUsage(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)
    coupon_id = db.Column(db.Integer, db.ForeignKey('coupon.id'), nullable=False)
    used_at = db.Column(db.DateTime, default=datetime.utcnow)

    # Garantir que um usuário só possa usar um cupom uma vez
    __table_args__ = (db.UniqueConstraint('user_id', 'coupon_id', name='_user_coupon_uc'),)

    def __repr__(self):
        return f'<UserCouponUsage UserID:{self.user_id} CouponID:{self.coupon_id}>'
# ---------------------