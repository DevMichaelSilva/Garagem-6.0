import os
import uuid
import base64
from PIL import Image
from io import BytesIO
import logging

logger = logging.getLogger(__name__)

# Configurações
IMAGE_UPLOAD_FOLDER = 'uploads/images'
MAX_IMAGE_SIZE_BYTES = 5 * 1024 * 1024  # 5MB
ALLOWED_EXTENSIONS = {'jpg', 'jpeg', 'png'}

def ensure_upload_folder_exists():
    """Garante que a pasta de upload exista com permissões adequadas"""
    if not os.path.exists(IMAGE_UPLOAD_FOLDER):
        try:
            os.makedirs(IMAGE_UPLOAD_FOLDER, exist_ok=True)
            # Em sistemas Unix/Linux, definir permissões
            if os.name != 'nt':  # Se não for Windows
                import stat
                os.chmod(IMAGE_UPLOAD_FOLDER, 
                         stat.S_IRWXU | stat.S_IRGRP | stat.S_IXGRP | stat.S_IROTH | stat.S_IXOTH)
        except Exception as e:
            print(f"Erro ao criar pasta de uploads: {e}")

def allowed_file(filename):
    """Verifica se a extensão do arquivo é permitida"""
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

def compress_image(image_data, max_size_bytes=MAX_IMAGE_SIZE_BYTES):
    """Comprime a imagem para garantir que esteja abaixo do tamanho máximo"""
    try:
        # Decodifica os dados base64
        format_data = image_data.split(';base64,')
        if len(format_data) != 2:
            return None, "Formato de imagem inválido"
            
        image_format = format_data[0].split('/')[-1]
        base64_data = format_data[1]
        
        # Converte base64 para bytes
        img_bytes = base64.b64decode(base64_data)
        img = Image.open(BytesIO(img_bytes))
        
        # Inicializa com qualidade alta
        quality = 95
        output = BytesIO()
        
        # Tenta comprimir a imagem reduzindo a qualidade gradualmente
        while quality > 30:  # Não deixaremos a qualidade cair abaixo de 30%
            output = BytesIO()
            img.save(output, format=image_format.upper(), quality=quality, optimize=True)
            if output.tell() <= max_size_bytes:
                break
            quality -= 10
        
        # Se ainda excede o tamanho mesmo com qualidade baixa, reduziremos dimensões
        if output.tell() > max_size_bytes:
            # Calcula a proporção para reduzir dimensões
            ratio = (max_size_bytes / output.tell()) ** 0.5
            new_width = int(img.width * ratio)
            new_height = int(img.height * ratio)
            img = img.resize((new_width, new_height), Image.LANCZOS)
            
            output = BytesIO()
            img.save(output, format=image_format.upper(), quality=quality, optimize=True)
        
        # Converte de volta para base64
        output.seek(0)
        compressed_data = base64.b64encode(output.getvalue()).decode('utf-8')
        return f"data:image/{image_format};base64,{compressed_data}", None
        
    except Exception as e:
        logger.error(f"Erro ao comprimir imagem: {str(e)}")
        return None, f"Erro ao processar imagem: {str(e)}"

def save_image(image_data):
    """Salva a imagem no disco e retorna o caminho"""
    try:
        ensure_upload_folder_exists()
        
        # Separa metadados e conteúdo
        format_data = image_data.split(';base64,')
        if len(format_data) != 2:
            return None, "Formato de imagem inválido"
            
        image_format = format_data[0].split('/')[-1]
        base64_data = format_data[1]
        
        # Gera um nome de arquivo único
        filename = f"{uuid.uuid4().hex}.{image_format}"
        filepath = os.path.join(IMAGE_UPLOAD_FOLDER, filename)
        
        # Salva o arquivo
        img_data = base64.b64decode(base64_data)
        with open(filepath, 'wb') as f:
            f.write(img_data)
        
        # Retorna o path relativo para armazenar no banco
        return filename, None
        
    except Exception as e:
        logger.error(f"Erro ao salvar imagem: {str(e)}")
        return None, f"Erro ao salvar imagem: {str(e)}"

def delete_image(filename):
    """Exclui uma imagem do disco"""
    try:
        filepath = os.path.join(IMAGE_UPLOAD_FOLDER, filename)
        if os.path.exists(filepath):
            os.remove(filepath)
            return True
        return False
    except Exception as e:
        logger.error(f"Erro ao excluir imagem {filename}: {str(e)}")
        return False