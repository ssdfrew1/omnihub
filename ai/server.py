from flask import Flask, request, jsonify, send_from_directory
from flask_cors import CORS
import requests
import json
import time
import logging
from datetime import datetime
import os
import uuid

app = Flask(__name__)
CORS(app)  # Разрешаем запросы с фронтенда

# Конфигурация
OLLAMA_HOST = "http://localhost:11434"
LOG_FILE = "ai_bot_logs.json"
API_TIMEOUT = 30

# Логирование
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Создаем файл логов если его нет
if not os.path.exists(LOG_FILE):
    with open(LOG_FILE, 'w', encoding='utf-8') as f:
        json.dump([], f, ensure_ascii=False)

class Logger:
    """Класс для логирования как в оригинальном боте"""
    def __init__(self, log_file: str):
        self.log_file = log_file
    
    def log_message(self, platform: str, user_id: str, username: str, 
                   message: str, response=None, command=None, 
                   error=None, model=None, restricted=False, jailbroken=False):
        
        log_data = {
            "timestamp": datetime.now().isoformat(),
            "platform": platform,
            "user_id": user_id,
            "username": username,
            "message": message,
            "response": response[:500] if response else None,  # Ограничиваем размер
            "command": command,
            "error": error,
            "model": model,
            "restricted": restricted,
            "jailbroken": jailbroken,
            "premium": False  # Для веб-интерфейса пока нет премиума
        }
        
        # Читаем текущие логи
        try:
            with open(self.log_file, 'r', encoding='utf-8') as f:
                logs = json.load(f)
        except:
            logs = []
        
        # Добавляем новый лог
        logs.append(log_data)
        
        # Сохраняем (ограничиваем размер до 1000 записей)
        if len(logs) > 1000:
            logs = logs[-1000:]
        
        with open(self.log_file, 'w', encoding='utf-8') as f:
            json.dump(logs, f, ensure_ascii=False, indent=2)
        
        # Выводим в консоль
        time_str = log_data['timestamp'][11:19]
        platform_icon = "🌐" if platform == "web" else "📱"
        
        if error:
            print(f"[{time_str}] {platform_icon} 💎 ОШИБКА")
            print(f"   {username}: {message[:50]}...")
            print(f"   Ошибка: {error}")
        elif restricted:
            print(f"[{time_str}] {platform_icon} 💎 🚫 ОГРАНИЧЕНИЕ")
        elif jailbroken:
            print(f"[{time_str}] {platform_icon} 💎 🔓 JAILBROKEN")
            print(f"   {model}: {response[:50] if response else ''}...")
        elif command:
            print(f"[{time_str}] {platform_icon} 💎 КОМАНДА")
            print(f"   {username}: {message[:50]}...")
        else:
            print(f"[{time_str}] {platform_icon} 💎 ДИАЛОГ")
            print(f"   {username}: {message[:50]}...")
            print(f"   {model}: {response[:50] if response else ''}...")
        
        return log_data

# Инициализируем логгер
log_manager = Logger(LOG_FILE)

# Хранилище сессий (в памяти)
user_sessions = {}

@app.route('/')
def index():
    return send_from_directory('.', 'index.html')

@app.route('/ai')
def ai_page():
    return send_from_directory('.', 'ai/index.html')

@app.route('/api/ollama/chat', methods=['POST'])
def ollama_chat():
    """Основной чат эндпоинт"""
    try:
        data = request.json
        model = data.get('model', 'llama2')
        messages = data.get('messages', [])
        
        # Получаем или создаем пользователя
        user_id = request.headers.get('X-User-Id', f'web_{str(uuid.uuid4())[:8]}')
        username = request.headers.get('X-Username', 'Web User')
        
        # Извлекаем последнее сообщение пользователя
        user_message = ""
        for msg in reversed(messages):
            if msg.get('role') == 'user':
                user_message = msg.get('content', '')
                break
        
        logger.info(f"Chat request from {username}: {user_message[:50]}...")
        
        # Отправляем запрос в Ollama
        start_time = time.time()
        response = requests.post(
            f"{OLLAMA_HOST}/api/chat",
            json=data,
            timeout=API_TIMEOUT
        )
        response_time = time.time() - start_time
        
        if response.status_code == 200:
            result = response.json()
            ai_response = result.get('message', {}).get('content', '') if 'message' in result else result.get('response', '')
            
            # Логируем успешный запрос
            log_manager.log_message(
                platform="web",
                user_id=user_id,
                username=username,
                message=user_message,
                response=ai_response,
                model=model,
                command=None,
                error=None
            )
            
            return jsonify({
                "success": True,
                "response": ai_response,
                "model": model,
                "response_time": response_time,
                "full_response": result
            }), 200
            
        else:
            error_msg = f"Ollama error: {response.status_code}"
            log_manager.log_message(
                platform="web",
                user_id=user_id,
                username=username,
                message=user_message,
                response=None,
                model=model,
                command=None,
                error=error_msg
            )
            
            return jsonify({
                "error": error_msg,
                "status_code": response.status_code
            }), 500
            
    except requests.exceptions.ConnectionError:
        error_msg = "Ollama server not running"
        log_manager.log_message(
            platform="web",
            user_id=user_id if 'user_id' in locals() else 'unknown',
            username=username if 'username' in locals() else 'unknown',
            message=user_message if 'user_message' in locals() else '',
            response=None,
            model=data.get('model', 'unknown') if 'data' in locals() else 'unknown',
            command=None,
            error=error_msg
        )
        
        return jsonify({
            "error": error_msg,
            "message": "Start Ollama with: ollama serve"
        }), 503
        
    except Exception as e:
        error_msg = str(e)
        log_manager.log_message(
            platform="web",
            user_id=user_id if 'user_id' in locals() else 'unknown',
            username=username if 'username' in locals() else 'unknown',
            message=user_message if 'user_message' in locals() else '',
            response=None,
            model=data.get('model', 'unknown') if 'data' in locals() else 'unknown',
            command=None,
            error=error_msg
        )
        
        return jsonify({
            "error": error_msg
        }), 500

@app.route('/api/ollama/tags', methods=['GET'])
def ollama_tags():
    """Список моделей"""
    try:
        response = requests.get(f"{OLLAMA_HOST}/api/tags", timeout=5)
        
        if response.status_code == 200:
            data = response.json()
            models = data.get('models', [])
            
            # Логируем запрос списка моделей
            log_manager.log_message(
                platform="web",
                user_id=request.headers.get('X-User-Id', 'system'),
                username="System",
                message="Get models list",
                response=f"Found {len(models)} models",
                model=None,
                command="/model list"
            )
            
            return jsonify({
                "success": True,
                "models": models,
                "count": len(models)
            }), 200
        else:
            return jsonify({
                "error": f"Ollama error: {response.status_code}",
                "models": []
            }), response.status_code
            
    except requests.exceptions.ConnectionError:
        return jsonify({
            "error": "Ollama not running",
            "models": []
        }), 503
    except Exception as e:
        return jsonify({
            "error": str(e),
            "models": []
        }), 500

@app.route('/api/ollama/status', methods=['GET'])
def ollama_status():
    """Проверка статуса Ollama"""
    try:
        start_time = time.time()
        response = requests.get(f"{OLLAMA_HOST}/api/tags", timeout=3)
        response_time = time.time() - start_time
        
        if response.status_code == 200:
            models = response.json().get('models', [])
            
            return jsonify({
                "status": "online",
                "response_time": round(response_time, 3),
                "models_count": len(models),
                "models": [m['name'] for m in models[:10]],  # Первые 10 моделей
                "ollama_version": response.headers.get('Ollama-Version', 'unknown')
            }), 200
        else:
            return jsonify({
                "status": "error",
                "error": f"HTTP {response.status_code}"
            }), 500
            
    except requests.exceptions.ConnectionError:
        return jsonify({
            "status": "offline",
            "error": "Cannot connect to Ollama"
        }), 503
    except Exception as e:
        return jsonify({
            "status": "error",
            "error": str(e)
        }), 500

@app.route('/api/chat/history', methods=['GET'])
def get_chat_history():
    """Получить историю чата из логов"""
    try:
        # Параметры запроса
        user_id = request.args.get('user_id')
        limit = int(request.args.get('limit', 50))
        
        # Читаем логи
        with open(LOG_FILE, 'r', encoding='utf-8') as f:
            logs = json.load(f)
        
        # Фильтруем по пользователю если указан
        if user_id:
            user_logs = [log for log in logs if log.get('user_id') == user_id]
        else:
            user_logs = logs
        
        # Берем последние N записей и форматируем
        recent_logs = user_logs[-limit:]
        
        # Группируем по диалогам (user + assistant)
        dialogs = []
        temp_dialog = []
        
        for log in recent_logs:
            if log.get('error') or log.get('command'):
                # Пропускаем ошибки и команды
                continue
            
            if log.get('response') and not log.get('error'):
                # Это ответ AI
                if temp_dialog:
                    temp_dialog.append({
                        'role': 'assistant',
                        'content': log['response'],
                        'timestamp': log['timestamp'],
                        'model': log['model']
                    })
                    dialogs.append(temp_dialog)
                    temp_dialog = []
            elif log.get('message') and not log.get('response'):
                # Это сообщение пользователя
                temp_dialog = [{
                    'role': 'user',
                    'content': log['message'],
                    'timestamp': log['timestamp'],
                    'username': log['username']
                }]
        
        return jsonify({
            "success": True,
            "user_id": user_id,
            "total_logs": len(user_logs),
            "recent_dialogs": dialogs[-10:],  # Последние 10 диалогов
            "timestamp": datetime.now().isoformat()
        }), 200
        
    except Exception as e:
        return jsonify({
            "error": str(e),
            "dialogs": []
        }), 500

@app.route('/api/logs/recent', methods=['GET'])
def get_recent_logs():
    """Получить последние логи"""
    try:
        limit = int(request.args.get('limit', 20))
        
        with open(LOG_FILE, 'r', encoding='utf-8') as f:
            logs = json.load(f)
        
        recent_logs = logs[-limit:]
        
        return jsonify({
            "success": True,
            "logs": recent_logs,
            "total": len(logs)
        }), 200
        
    except Exception as e:
        return jsonify({
            "error": str(e),
            "logs": []
        }), 500

@app.route('/api/user/create', methods=['POST'])
def create_user():
    """Создать или получить пользователя"""
    data = request.json
    username = data.get('username', 'Web User')
    
    # Генерируем ID пользователя
    user_id = f"web_{str(uuid.uuid4())[:8]}"
    
    # Сохраняем в сессии
    user_sessions[user_id] = {
        'username': username,
        'created_at': datetime.now().isoformat(),
        'last_active': datetime.now().isoformat(),
        'message_count': 0
    }
    
    # Логируем создание пользователя
    log_manager.log_message(
        platform="web",
        user_id=user_id,
        username=username,
        message="User created",
        response=None,
        model=None,
        command="register"
    )
    
    return jsonify({
        "success": True,
        "user_id": user_id,
        "username": username,
        "session": user_sessions[user_id]
    }), 200

@app.route('/api/models/check', methods=['POST'])
def check_models():
    """Проверить доступность моделей"""
    try:
        data = request.json
        models_to_check = data.get('models', [])
        
        results = []
        for model_name in models_to_check:
            try:
                test_response = requests.post(
                    f"{OLLAMA_HOST}/api/generate",
                    json={
                        "model": model_name,
                        "prompt": "test",
                        "stream": False,
                        "options": {"num_predict": 5}
                    },
                    timeout=5
                )
                
                results.append({
                    "model": model_name,
                    "status": "online" if test_response.status_code == 200 else "error",
                    "status_code": test_response.status_code
                })
                
            except Exception as e:
                results.append({
                    "model": model_name,
                    "status": "offline",
                    "error": str(e)
                })
        
        return jsonify({
            "success": True,
            "results": results,
            "checked_at": datetime.now().isoformat()
        }), 200
        
    except Exception as e:
        return jsonify({
            "error": str(e),
            "results": []
        }), 500

if __name__ == '__main__':
    print("🚀 Запуск Omni AI Server...")
    print("=" * 50)
    print(f"📡 Ollama Host: {OLLAMA_HOST}")
    print(f"📝 Логи: {LOG_FILE}")
    print("🌐 Web Interface: http://localhost:5000")
    print("🤖 AI Page: http://localhost:5000/ai")
    print("\nДоступные API эндпоинты:")
    print("  GET  /api/ollama/status    - статус Ollama")
    print("  GET  /api/ollama/tags      - список моделей")
    print("  POST /api/ollama/chat      - AI чат (основной)")
    print("  GET  /api/chat/history     - история чата")
    print("  GET  /api/logs/recent      - последние логи")
    print("  POST /api/user/create      - создать пользователя")
    print("  POST /api/models/check     - проверить модели")
    print("\nЗапуск сервера на порту 5000...")
    print("=" * 50)
    
    app.run(host='0.0.0.0', port=5000, debug=True)