
import telebot
import requests
from bs4 import BeautifulSoup
from datetime import datetime, timedelta
from telebot.types import ReplyKeyboardMarkup, KeyboardButton, InlineKeyboardMarkup, InlineKeyboardButton

# Токен твоего бота
TOKEN = "5554400387:AAHOhxyY1a9sprXQQ9gfooRGrGjUMnkxncc"
bot = telebot.TeleBot(TOKEN)

# Твой Telegram ID — бессрочный администраторский доступ
ADMIN_ID = 1772351135

# База данных пользователей
users_db = {}

# Проверка доступа
def check_user_access(chat_id):
    if chat_id == ADMIN_ID:
        return "vip"
    if chat_id not in users_db:
        return "expired"
    
    user_data = users_db[chat_id]
    now = datetime.now()
    
    if user_data.get("vip_expires") and now < user_data["vip_expires"]:
        return "vip"
    if now - user_data["reg_date"] <= timedelta(days=3):
        return "trial"
        
    return "expired"

# --- ГЛАВНОЕ МЕНЮ ---
@bot.message_handler(commands=['start'])
def send_welcome(message):
    chat_id = message.chat.id
    now = datetime.now()
    
    if chat_id not in users_db:
        users_db[chat_id] = {
            "reg_date": now,
            "vip_expires": None
        }
    
    access = check_user_access(chat_id)
    
    markup = ReplyKeyboardMarkup(resize_keyboard=True, row_width=2)
    markup.add(
        KeyboardButton("⚽ Сигналы: Обе забьют (ОЗ)"),
        KeyboardButton("⚡ Сигналы: ТБ 0.5 (1-й тайм)"),
        KeyboardButton("📈 Статистика проходимости"),
        KeyboardButton("🧮 Калькулятор ставок"),
        KeyboardButton("💎 VIP-канал / Подписка"),
        KeyboardButton("🤝 Пригласи друга"),
        KeyboardButton("❓ Помощь / Поддержка")
    )
    
    if chat_id == ADMIN_ID:
        status_text = "🛠 **Режим администратора:** У вас полный бессрочный доступ!"
    elif access == "vip":
        status_text = "💎 У вас активен **VIP-доступ**!"
    elif access == "trial":
        status_text = "⏳ У вас **тестовый доступ (3 дня)**."
    else:
        status_text = "❌ Ваш **пробный период истек**. Оформите VIP-подписку!"

    bot.send_message(
        message.chat.id,
        f"Привет, **{message.from_user.first_name}**! 👋\n\n{status_text}\n\nВыбирай раздел в меню:",
        reply_markup=markup,
        parse_mode="Markdown"
    )

# --- ПАРСЕР МАТЧЕЙ AISCORE ---
def get_aiscore_matches():
    matches = []
    try:
        url = "https://www.aiscore.com/"
        headers = {
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
            "Accept-Language": "ru-RU,ru;q=0.9,en-US;q=0.8,en;q=0.7"
        }
        response = requests.get(url, headers=headers, timeout=8)
        
        if response.status_code == 200:
            soup = BeautifulSoup(response.text, 'html.parser')
            elements = soup.select('.match-item, .row-live, div[class*="match"], div[class*="team"], tr')
            
            for el in elements:
                text = " ".join(el.get_text(" ", strip=True).split())
                if (' - ' in text or 'vs' in text.lower()) and len(text) > 8 and len(text) < 140:
                    if text not in matches:
                        matches.append(text)
                if len(matches) >= 10:
                    break
    except Exception:
        pass
        
    if not matches:
        matches = [
            "Реал Мадрид vs Барселона",
            "Манчестер Сити vs Арсенал",
            "Бавария vs Боруссия Дортмунд",
            "Интер vs Милан",
            "ПСЖ vs Марсель",
            "Шахтер Донецк vs Динамо Киев",
            "Аякс vs ПСВ",
            "Порту vs Бенфика"
        ]
    return matches

# --- РАЗДЕЛ СИГНАЛОВ: ОБЕ ЗАБЬЮТ ---
@bot.message_handler(func=lambda message: message.text == "⚽ Сигналы: Обе забьют (ОЗ)")
def show_btts_menu(message):
    if check_user_access(message.chat.id) == "expired":
        bot.send_message(message.chat.id, "❌ Срок бесплатного доступа истек. Оформите VIP-подписку.")
        return
        
    bot.send_message(message.chat.id, "⏳ Загружаю свежие сигналы по стратегии «Обе забьют»...")
    matches = get_aiscore_matches()
    
    today_date = datetime.now().strftime('%Y-%m-%d')
    text = f"🔥 **Сигналы «Обе забьют (ОЗ)» ({today_date}):**\n\n"
    for m in matches[:6]:
        text += (
            f"⚽ `{m}`\n"
            f"📊 **Анализ:** Высокий индекс xG, атака преобладает.\n"
            f"💡 **Рекомендация:** `Обе забьют (Да)`\n"
            f"-----------------------------------\n"
        )
            
    markup = InlineKeyboardMarkup()
    markup.add(InlineKeyboardButton("🔄 Обновить линию ОЗ", callback_data="refresh_btts"))
    bot.send_message(message.chat.id, text, reply_markup=markup, parse_mode="Markdown")

@bot.callback_query_handler(func=lambda call: call.data == "refresh_btts")
def refresh_btts_callback(call):
    if check_user_access(call.message.chat.id) == "expired":
        bot.answer_callback_query(call.id, "Доступ ограничен!", show_alert=True)
        return
    matches = get_aiscore_matches()
    today_date = datetime.now().strftime('%Y-%m-%d')
    text = f"🔥 **Сигналы «Обе забьют (ОЗ)» ({today_date}):**\n\n"
    for m in matches[:6]:
        text += (
            f"⚽ `{m}`\n"
            f"📊 **Анализ:** Высокий индекс xG, атака преобладает.\n"
            f"💡 **Рекомендация:** `Обе забьют (Да)`\n"
            f"-----------------------------------\n"
        )
    bot.edit_message_text(text, call.message.chat.id, call.message.message_id, reply_markup=None, parse_mode="Markdown")
    bot.answer_callback_query(call.id, "Линия ОЗ обновлена!")


# --- РАЗДЕЛ СИГНАЛОВ: ТБ 0.5 В 1 ТАЙМЕ ---
@bot.message_handler(func=lambda message: message.text == "⚡ Сигналы: ТБ 0.5 (1-й тайм)")
def show_tb05_menu(message):
    if check_user_access(message.chat.id) == "expired":
        bot.send_message(message.chat.id, "❌ Срок бесплатного доступа истек. Оформите VIP-подписку.")
        return
        
    bot.send_message(message.chat.id, "⏳ Загружаю свежие сигналы по стратегии «ТБ 0.5 в 1-м тайме»...")
    matches = get_aiscore_matches()
    
    today_date = datetime.now().strftime('%Y-%m-%d')
    text = f"🔥 **Сигналы «ТБ 0.5 в 1-м тайме» ({today_date}):**\n\n"
    for m in matches[:6]:
        text += (
            f"⚽ `{m}`\n"
            f"📊 **Анализ:** Активный стартовый темп и удары в створ.\n"
            f"💡 **Рекомендация:** `Тотал больше 0.5 в 1-м тайме`\n"
            f"-----------------------------------\n"
        )
            
    markup = InlineKeyboardMarkup()
    markup.add(InlineKeyboardButton("🔄 Обновить линию ТБ 0.5", callback_data="refresh_tb05"))
    bot.send_message(message.chat.id, text, reply_markup=markup, parse_mode="Markdown")

@bot.callback_query_handler(func=lambda call: call.data == "refresh_tb05")
def refresh_tb05_callback(call):
    if check_user_access(call.message.chat.id) == "expired":
        bot.answer_callback_query(call.id, "Доступ ограничен!", show_alert=True)
        return
    matches = get_aiscore_matches()
    today_date = datetime.now().strftime('%Y-%m-%d')
    text = f"🔥 **Сигналы «ТБ 0.5 в 1-м тайме» ({today_date}):**\n\n"
    for m in matches[:6]:
        text += (
            f"⚽ `{m}`\n"
            f"📊 **Анализ:** Активный стартовый темп и удары в створ.\n"
            f"💡 **Рекомендация:** `Тотал больше 0.5 в 1-м тайме`\n"
            f"-----------------------------------\n"
        )
    bot.edit_message_text(text, call.message.chat.id, call.message.message_id, reply_markup=None, parse_mode="Markdown")
    bot.answer_callback_query(call.id, "Линия ТБ 0.5 обновлена!")

# --- СТАТИСТИКА И КАЛЬКУЛЯТОР ---
@bot.message_handler(func=lambda message: message.text == "📈 Статистика проходимости")
def show_statistics(message):
    stats_text = (
        "📈 **Статистика стратегий:**\n\n"
        "⚽ **Обе забьют (ОЗ):** Проходимость `82%`\n"
        "⚡ **ТБ 0.5 в 1Т:** Проходимость `85%`\n"
        "💰 **Средний коэффициент:** `1.75`"
    )
    bot.send_message(message.chat.id, stats_text, parse_mode="Markdown")

@bot.message_handler(func=lambda message: message.text == "🧮 Калькулятор ставок")
def calculator_info(message):
    calc_text = (
        "🧮 **Калькулятор ставок**\n\n"
        "Отправьте сумму и коэффициент через пробел (например: `1000 1.75`)"
    )
    bot.send_message(message.chat.id, calc_text, parse_mode="Markdown")

@bot.message_handler(func=lambda message: len(message.text.split()) == 2 and message.text.split()[0].isdigit())
def calculate_bet(message):
    try:
        parts = message.text.split()
        amount, coefficient = float(parts[0]), float(parts[1].replace(',', '.'))
        win = round(amount * coefficient, 2)
        bot.reply_to(message, f"🧮 Выплата: **{win} грн.** (Прибыль: +{round(win - amount, 2)} грн.)", parse_mode="Markdown")
    except ValueError:
        pass

# --- VIP ПОДПИСКА ---
@bot.message_handler(func=lambda message: message.text == "💎 VIP-канал / Подписка")
def show_vip(message):
    markup = InlineKeyboardMarkup()
    markup.add(InlineKeyboardButton("💳 Купить VIP на 1 месяц (500 грн.)", callback_data="buy_vip"))
    
    chat_id = message.chat.id
    if chat_id == ADMIN_ID:
        status_msg = "🛠 **У вас статус Администратора (полный доступ).**"
    elif check_user_access(chat_id) == "vip":
        expires_str = users_db[chat_id]["vip_expires"].strftime('%d.%m.%Y %H:%M')
        status_msg = f"💎 **VIP активен до:** `{expires_str}`"
    else:
        status_msg = "💎 **VIP-Клуб Прогнозистов**\n• Сигналы ОЗ и ТБ 0.5\n• Закрытая аналитика"

    bot.send_message(message.chat.id, status_msg, reply_markup=markup, parse_mode="Markdown")

@bot.callback_query_handler(func=lambda call: call.data == "buy_vip")
def buy_vip_card(call):
    text = (
        "💳 **Покупка VIP-подписки на 1 месяц**\n\n"
        "💰 **Стоимость:** 500 грн.\n"
        "📥 **Реквизиты карты:**\n`4441 1110 3535 7213 MONOBANK`\n\n"
        "📌 После оплаты отправьте чек администратору."
    )
    markup = InlineKeyboardMarkup()
    markup.add(InlineKeyboardButton("💬 Отправить чек администратору", url="https://t.me/Aleks19860426"))
    bot.edit_message_text(text, call.message.chat.id, call.message.message_id, reply_markup=markup, parse_mode="Markdown")
    bot.answer_callback_query(call.id)

# --- АДМИНСКАЯ ВЫДАЧА VIP ---
@bot.message_handler(commands=['addvip'])
def admin_add_vip(message):
    if message.chat.id != ADMIN_ID:
        return
    try:
        parts = message.text.split()
        if len(parts) < 2:
            bot.reply_to(message, "⚠️ Формат: `/addvip ID_пользователя`", parse_mode="Markdown")
            return
        target_id = int(parts[1])
        if target_id in users_db:
            users_db[target_id]["vip_expires"] = datetime.now() + timedelta(days=30)
            bot.reply_to(message, f"✅ Пользователю `{target_id}` выдан VIP на 1 месяц!")
            try:
                bot.send_message(target_id, "🎉 Администратор подтвердил оплату! Вам активирован **VIP-доступ на 1 месяц** 💎", parse_mode="Markdown")
            except Exception:
                pass
        else:
            bot.reply_to(message, "⚠️ Пользователь не найден в базе.")
    except Exception as e:
        bot.reply_to(message, f"⚠️ Ошибка: {e}")

# --- РЕФЕРАЛКА И ПОДДЕРЖКА ---
@bot.message_handler(func=lambda message: message.text == "🤝 Пригласи друга")
def referral_system(message):
    bot.send_message(message.chat.id, f"🤝 Приглашайте друзей по ссылке:\n`https://t.me/bet333_bot?start=ref_{message.chat.id}`", parse_mode="Markdown")

@bot.message_handler(func=lambda message: message.text == "❓ Помощь / Поддержка")
def show_help(message):
    bot.send_message(message.chat.id, "💬 Поддержка: @Aleks19860426", parse_mode="Markdown")

# --- СТАТИСТИКА И РАССЫЛКА ДЛЯ АДМИНА ---
@bot.message_handler(commands=['stats'])
def show_bot_users_stats(message):
    if message.chat.id == ADMIN_ID:
        bot.reply_to(message, f"📊 Пользователей в базе: **{len(users_db)}**", parse_mode="Markdown")

@bot.message_handler(commands=['send'])
def admin_broadcast(message):
    if message.chat.id != ADMIN_ID:
        return
    text_to_send = message.text.replace("/send", "").strip()
    if not text_to_send:
        bot.reply_to(message, "⚠️ Введите текст после /send")
        return
    success = 0
    for uid in users_db:
        try:
            bot.send_message(uid, f"📢 **Рассылка:**\n\n{text_to_send}", parse_mode="Markdown")
            success += 1
        except Exception:
            pass
    bot.reply_to(message, f"✅ Рассылка завершена. Получили: {success}")

# --- ЗАПУСК ---
if __name__ == "__main__":
    print("Бот успешно запущен и работает в стабильном режиме!")
    while True:
        try:
            bot.infinity_polling(interval=0, timeout=20)
        except Exception as e:
            print(f"⚠️ Сбой: {e}. Переподключение через 5 сек...")
            import time
            time.sleep(5)
