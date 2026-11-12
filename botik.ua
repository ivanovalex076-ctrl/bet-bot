import telebot

TOKEN = '5554400387:AAHOhxyY1a9sprXQQ9gfooRGrGjUMnkxncc'
bot = telebot.TeleBot(TOKEN)

from flask import Flask
import threading

app = Flask('')


@app.route('/')
def home():
  return 'I am alive!'


def run():
  app.run(host='0.0.0.0', port=8080)


threading.Thread(target=run).start()
bot.infinity_polling()
