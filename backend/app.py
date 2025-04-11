from flask import Flask, request, jsonify
from flask_cors import CORS
import os
from extensions import db
from models import User, Vehicle, Maintenance
from routes.auth_routes import auth_bp
from routes.vehicle_routes import vehicle_bp
from routes.maintenance_routes import maintenance_bp
from werkzeug.security import generate_password_hash, check_password_hash

app = Flask(__name__)
# Configuração correta do CORS para permitir todas as origens
CORS(app, resources={r"/api/*": {"origins": "*"}}, supports_credentials=True)

# Configuração do banco de dados
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///garagem.db'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
app.config['SECRET_KEY'] = 'sua_chave_secreta_aqui'

# Inicialização do banco de dados
db.init_app(app)

# Registro de rotas
app.register_blueprint(auth_bp, url_prefix='/api/auth')
app.register_blueprint(vehicle_bp, url_prefix='/api/vehicles')
app.register_blueprint(maintenance_bp, url_prefix='/api/maintenances')

# Criação das tabelas
with app.app_context():
    db.create_all()

if __name__ == '__main__': 
    app.run(debug=True)