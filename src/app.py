import time
from flask import Flask
from redis import Redis
import os
from prometheus_client import Counter, start_http_server, generate_latest

app = Flask(__name__)

redis_host = os.environ.get('REDIS_HOST', 'redis-service')
redis_port = 6379

# redis = Redis(host='redis', port=6379)
redis = Redis(host=redis_host, port=redis_port)

@app.route('/')
def hello():
    redis.incr('hits')
    counter = str(redis.get('hits'),'utf-8')
    return "Bem-vindo! Esta página foi vizualizada "+counter+" vezes!"

@app.route('/metrics')
def metrics():
    return generate_latest()

if __name__ == "__main__":
    app.run(host="0.0.0.0", debug=True)
