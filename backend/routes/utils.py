from models import TIER_LIMITS, User, Vehicle, Maintenance # Importar modelos e limites
from datetime import datetime

def check_limits(user: User, action: str, count: int = 1) -> bool:
    """
    Verifica se o usuário pode realizar uma ação com base em seu tier e limites.

    Args:
        user: O objeto User.
        action: A ação a ser verificada ('add_vehicle', 'add_service', 'add_photo').
        count: O número de itens sendo adicionados (útil para fotos).

    Returns:
        True se a ação for permitida, False caso contrário.
    """
    if user.is_admin:
        return True # Admin não tem limites

    tier = user.tier
    limits = TIER_LIMITS.get(tier)

    if not limits:
        return False # Tier desconhecido, bloqueia por segurança

    # Verificar se a assinatura (se premium) está ativa
    if tier != 'Free' and (not user.subscription_end_date or user.subscription_end_date < datetime.utcnow()):
        # Se for premium mas a assinatura expirou, trata como Free para limites
        tier = 'Free'
        limits = TIER_LIMITS.get(tier)
        if not limits: return False # Segurança

    if action == 'add_vehicle':
        current_vehicles = Vehicle.query.filter_by(user_id=user.id).count()
        return current_vehicles < limits['vehicles']

    elif action == 'add_service':
        # Contar serviços apenas do usuário atual
        current_services = Maintenance.query.join(Vehicle).filter(Vehicle.user_id == user.id).count()
        return current_services < limits['services']

    elif action == 'add_photo':
        # Usa a contagem armazenada no usuário
        return (user.photo_count + count) <= limits['photos']

    return False # Ação desconhecida
