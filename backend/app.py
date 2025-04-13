from flask import Flask, send_from_directory
from flask_cors import CORS
import os   
from extensions import db
from models import User, Vehicle, Maintenance, MaintenanceImage
from routes.auth_routes import auth_bp
from routes.vehicle_routes import vehicle_bp
from routes.maintenance_routes import maintenance_bp
from routes.image_routes import image_bp
from utils.image_utils import IMAGE_UPLOAD_FOLDER, ensure_upload_folder_exists
from werkzeug.security import generate_password_hash, check_password_hash

def create_app():
    app = Flask(__name__)
    
    # Configuração do CORS mais permissiva para desenvolvimento
    CORS(app, resources={r"/api/*": {"origins": "*"}}, supports_credentials=True)

    # Configuração do banco de dados
    app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///garagem.db'
    app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
    app.config['SECRET_KEY'] = 'sua_chave_secreta_aqui'
    app.config['MAX_CONTENT_LENGTH'] = 16 * 1024 * 1024  # Limite máximo para upload (16MB)
    app.config['UPLOAD_FOLDER'] = IMAGE_UPLOAD_FOLDER

    # Inicialização do banco de dados com o app
    db.init_app(app)

    # Registro de rotas
    app.register_blueprint(auth_bp, url_prefix='/api/auth')
    app.register_blueprint(vehicle_bp, url_prefix='/api/vehicles')
    app.register_blueprint(maintenance_bp, url_prefix='/api/maintenances')
    app.register_blueprint(image_bp, url_prefix='/api/images')

    # Criação das tabelas e pasta de uploads
    with app.app_context():
        db.create_all()
        ensure_upload_folder_exists()

    # Rota para servir imagens
    @app.route('/uploads/images/<filename>')
    def uploaded_file(filename):
        return send_from_directory(app.config['UPLOAD_FOLDER'], filename)

    return app

if __name__ == '__main__':
    app = create_app()
    app.run(debug=True)