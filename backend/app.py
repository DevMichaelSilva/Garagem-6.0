import logging
from flask import Flask, request, jsonify
from flask_cors import CORS
import os
from flask_migrate import Migrate
from extensions import db
from models import User, Vehicle, Maintenance, MaintenanceImage
import firebase_admin
from firebase_admin import credentials, auth

def create_app():
    app = Flask(__name__)

    # Configuração do CORS mais permissiva para desenvolvimento
    CORS(app, resources={r"/api/*": {"origins": "*"}}, supports_credentials=True)

    # Configuração do banco de dados
    app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///garagem.db'
    app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

    # Inicializar Firebase Admin SDK
    try:
        # Caminho para o arquivo da chave de serviço
        cred_path = os.path.join(os.path.dirname(__file__), 'firebase-service-account.json')
        cred = credentials.Certificate(cred_path)
        firebase_admin.initialize_app(cred)
        print("Firebase Admin SDK inicializado com sucesso.")
    except Exception as e:
        print(f"Erro ao inicializar Firebase Admin SDK: {e}")

    # Inicialização do banco de dados com o app
    db.init_app(app)

    # Registro de rotas
    from routes.auth_routes import auth_bp
    from routes.vehicle_routes import vehicle_bp
    from routes.maintenance_routes import maintenance_bp

    app.register_blueprint(auth_bp, url_prefix='/api/auth')
    app.register_blueprint(vehicle_bp, url_prefix='/api/vehicles')
    app.register_blueprint(maintenance_bp, url_prefix='/api/maintenances')

    # Criação das tabelas
    with app.app_context():
        db.create_all()
        print("Banco de dados criado/recriado com sucesso!")

    return app

if __name__ == '__main__':
    app = create_app()
    app.run(debug=True, host='0.0.0.0', port=5000)