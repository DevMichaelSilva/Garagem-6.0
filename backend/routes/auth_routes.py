from flask import Blueprint, request, jsonify, current_app
from models import User  # Importando User do módulo models
import jwt
import datetime
from extensions import db
from werkzeug.security import generate_password_hash, check_password_hash
import re

auth_bp = Blueprint('auth', __name__)

@auth_bp.route('/register', methods=['POST'])
def register():
    data = request.get_json()
    
    # Verificar se todos os campos obrigatórios estão presentes
    required_fields = ['username', 'email', 'password', 'cpf', 'phone', 'confirm_password']
    for field in required_fields:
        if field not in data:
            return jsonify({"message": f"Campo '{field}' é obrigatório"}), 400
    
    # Verificar se as senhas coincidem
    if data['password'] != data['confirm_password']:
        return jsonify({"message": "As senhas não coincidem"}), 400
    
    # Verificar se o email já está em uso
    if User.query.filter_by(email=data['email']).first():
        return jsonify({"message": "Email já cadastrado"}), 400
    
    # Verificar se o nome de usuário já está em uso
    if User.query.filter_by(username=data['username']).first():
        return jsonify({"message": "Nome de usuário já em uso"}), 400
    
    # Verificar se o CPF já está cadastrado e se existe um atributo cpf no modelo
    if hasattr(User, 'cpf') and User.query.filter_by(cpf=data['cpf']).first():
        return jsonify({"message": "CPF já cadastrado"}), 400
    
    # Validar formato do email - Correção da expressão regular
    email_pattern = r'^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$'
    if not re.match(email_pattern, data['email']):
        return jsonify({"message": "Formato de email inválido"}), 400
    
    # Validar CPF (remover caracteres não numéricos)
    cpf_digits = re.sub(r'[^0-9]', '', data['cpf'])
    if len(cpf_digits) != 11:
        return jsonify({"message": "CPF inválido"}), 400
    
    # Validar número de telefone
    phone_digits = re.sub(r'[^0-9]', '', data['phone'])
    if len(phone_digits) < 10:
        return jsonify({"message": "Telefone inválido"}), 400
    
    # Criar novo usuário
    try:
        # Verificar quais campos o modelo User suporta
        user_fields = {
            'username': data['username'],
            'email': data['email'],
            'password_hash': generate_password_hash(data['password'])
        }
        
        # Adicionar campos opcionais se existirem no modelo
        if hasattr(User, 'cpf'):
            user_fields['cpf'] = cpf_digits
        if hasattr(User, 'phone'):
            user_fields['phone'] = phone_digits
            
        new_user = User(**user_fields)
        
        # Salvar usuário no banco de dados
        db.session.add(new_user)
        db.session.commit()
        
        return jsonify({
            "message": "Usuário registrado com sucesso",
            "user_id": new_user.id
        }), 201
    except Exception as e:
        db.session.rollback()
        return jsonify({"message": f"Erro ao registrar usuário: {str(e)}"}), 500

@auth_bp.route('/login', methods=['POST'])
def login():
    data = request.get_json()
    
    # Verificar se email e senha foram fornecidos
    if 'email' not in data or 'password' not in data:
        return jsonify({"message": "Email e senha são obrigatórios"}), 400
    
    # Buscar usuário pelo email
    user = User.query.filter_by(email=data['email']).first()
    
    # Verificar se o usuário existe e a senha está correta
    if not user or not check_password_hash(user.password_hash, data['password']):
        return jsonify({"message": "Email ou senha inválidos"}), 401
    
    # Gera o token JWT
    token = jwt.encode({
        'user_id': user.id,
        'exp': datetime.datetime.utcnow() + datetime.timedelta(days=1)
    }, current_app.config['SECRET_KEY'], algorithm="HS256")
    
    return jsonify({
        "message": "Login realizado com sucesso",
        "token": token,
        "user_id": user.id,
        "username": user.username,
        "email": user.email
    }), 200

@auth_bp.route('/verify', methods=['GET'])
def verify_token():
    # Lógica para verificar o token JWT
    # Isso seria implementado quando você adicionar autenticação JWT
    return jsonify({"message": "Token válido"}), 200