from flask import Blueprint, request, jsonify, current_app
from models import User
from extensions import db
# Remover imports não utilizados: jwt, datetime, generate_password_hash, check_password_hash, re
from firebase_admin import auth # Importar auth do firebase_admin
from functools import wraps # Importar wraps
from datetime import datetime # Adicionar datetime

auth_bp = Blueprint('auth', __name__)

# Decorator para verificar o token Firebase ID
def firebase_token_required(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        id_token = request.headers.get('Authorization')
        if not id_token:
            return jsonify({"message": "Token de autorização não fornecido"}), 401

        # Remover 'Bearer ' se presente
        if id_token.startswith('Bearer '):
            id_token = id_token.split('Bearer ')[1]

        try:
            # Verificar o ID token usando o Firebase Admin SDK.
            # Isso verifica a assinatura, expiração e aud (audience).
            decoded_token = auth.verify_id_token(id_token)
            firebase_uid = decoded_token['uid']

            # Buscar ou criar usuário no banco de dados local
            current_user = User.query.filter_by(firebase_uid=firebase_uid).first()

            # Se o usuário não existe no DB local, mas o token é válido,
            # podemos criá-lo aqui ou deixar a rota /sync_user fazer isso.
            # Por segurança, vamos apenas passar o UID por enquanto.
            # O endpoint protegido pode então buscar o usuário pelo UID.
            # Ou podemos adicionar o usuário ao contexto da requisição (g)
            # from flask import g
            # g.current_user = current_user
            # g.firebase_uid = firebase_uid

        except auth.ExpiredIdTokenError:
            return jsonify({"message": "Token expirado"}), 401
        except auth.InvalidIdTokenError as e:
            print(f"Token inválido: {e}")
            return jsonify({"message": "Token inválido"}), 401
        except Exception as e:
            print(f"Erro na verificação do token: {e}")
            return jsonify({"message": "Erro interno na verificação do token"}), 500

        # Passa o firebase_uid para a função da rota
        return f(firebase_uid, *args, **kwargs)
    return decorated_function


# Rota para sincronizar/criar usuário no backend após login/registro no Firebase
@auth_bp.route('/sync_user', methods=['POST'])
@firebase_token_required # Usa o novo decorator
def sync_user(firebase_uid):
    """
    Chamado pelo frontend após login/registro bem-sucedido no Firebase.
    Cria ou atualiza o usuário no banco de dados local.
    """
    try:
        # Obter informações do usuário do Firebase Auth usando o UID
        firebase_user = auth.get_user(firebase_uid)
        email = firebase_user.email
        name = firebase_user.display_name

        # Verificar se o usuário já existe no banco de dados local
        user = User.query.filter_by(firebase_uid=firebase_uid).first()

        if not user:
            # Se não existe, cria um novo usuário
            # Tenta pegar dados adicionais do request (enviados pelo frontend após registro)
            data = request.get_json()
            cpf = data.get('cpf') if data else None
            phone = data.get('phone') if data else None

            user = User(
                firebase_uid=firebase_uid,
                email=email,
                username=name or email, # Usa nome ou email como username padrão
                cpf=cpf, # Salva CPF se fornecido
                phone=phone # Salva telefone se fornecido
            )
            db.session.add(user)
            db.session.commit()
            print(f"Novo usuário criado no DB local: UID={firebase_uid}, Email={email}")
            # --- Retornar dados do usuário ---
            return jsonify({
                "message": "Usuário sincronizado com sucesso (novo)",
                "user_id": user.id,
                "tier": user.tier,
                "subscription_end_date": user.subscription_end_date.isoformat() if user.subscription_end_date else None
            }), 201
            # ---------------------------------
        else:
            # Se já existe, pode opcionalmente atualizar informações (nome, etc.)
            updated = False
            if user.username != name and name:
                user.username = name
                updated = True
            # Poderia adicionar lógica para atualizar CPF/Telefone se eles estiverem vazios no DB
            # e forem fornecidos na requisição (ex: primeiro login após registro)
            data = request.get_json()
            if data:
                if not user.cpf and data.get('cpf'):
                    user.cpf = data.get('cpf')
                    updated = True
                if not user.phone and data.get('phone'):
                    user.phone = data.get('phone')
                    updated = True

            if updated:
                db.session.commit()
                print(f"Usuário atualizado no DB local: UID={firebase_uid}")

            # --- Retornar dados do usuário ---
            return jsonify({
                "message": "Usuário sincronizado com sucesso (existente)",
                "user_id": user.id,
                "tier": user.tier,
                "subscription_end_date": user.subscription_end_date.isoformat() if user.subscription_end_date else None
            }), 200
            # ---------------------------------

    except auth.UserNotFoundError:
        return jsonify({"message": "Usuário Firebase não encontrado"}), 404
    except Exception as e:
        db.session.rollback()
        print(f"Erro ao sincronizar usuário: {e}")
        return jsonify({"message": f"Erro ao sincronizar usuário: {str(e)}"}), 500


# Remover rotas /register, /login e /verify
# @auth_bp.route('/register', methods=['POST']) ... (REMOVIDO)
# @auth_bp.route('/login', methods=['POST']) ... (REMOVIDO)
# @auth_bp.route('/verify', methods=['GET']) ... (REMOVIDO)