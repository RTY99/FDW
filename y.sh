#!/data/data/com.termux/files/usr/bin/bash

# สร้างฟังก์ชัน ASCII Art Logo
show_logo() {
    echo -e "\033[32m"
    cat << "EOF"
╭━━━╮╱╱╱╱╱╭━━━╮
┃╭━╮┃╱╱╱╱╱┃╭━╮┃
┃╰━━┳━━┳━━┫┃╱┃┣━━┳━╮
╰━━╮┃╭╮┃╭╮┃┃╱┃┃╭╮┃╭╯
┃╰━╯┃╰╯┃╰╯┃╰━╯┃╰╯┃┃
╰━━━┫╭━┫╭━┻━━━┻━━┻╯
╱╱╱╱┃┃╱┃┃
╱╱╱╱╰╯╱╰╯ YouTube Downloader
EOF
    echo -e "\033[0m"
}

# สร้างฟังก์ชัน Progress Bar
show_progress() {
    local width=50
    local percentage=$1
    local filled=$(printf "%.0f" $(echo "$percentage * $width / 100" | bc -l))
    local empty=$((width - filled))
    printf "\r["
    printf "%${filled}s" | tr ' ' '█'
    printf "%${empty}s" | tr ' ' '░'
    printf "] %3d%%" $percentage
}

# ตรวจสอบและติดตั้งแพ็คเกจ
check_and_install() {
    local package=$1
    echo -e "\033[34m📦 กำลังตรวจสอบ $package...\033[0m"
    if ! command -v $package >/dev/null 2>&1; then
        echo -e "\033[33m⚡ กำลังติดตั้ง $package...\033[0m"
        pkg install $package -y
    fi
    echo -e "\033[32m✓ ติดตั้ง $package เรียบร้อย\033[0m"
}

# แสดง Logo
clear
show_logo

# ติดตั้งแพ็คเกจที่จำเป็น
echo -e "\n\033[36m🔄 กำลังอัพเดทระบบ...\033[0m"
pkg update -y && pkg upgrade -y

for pkg in python ffmpeg nginx openssh; do
    check_and_install $pkg
done

pip install yt-dlp flask

# ตั้งค่าพื้นฐาน
PORT=8080
DOWNLOAD_DIR="/sdcard/Download"
mkdir -p "$DOWNLOAD_DIR"
termux-setup-storage

# สร้างไฟล์ HTML ที่สวยงาม
cat << 'EOF' > /data/data/com.termux/files/usr/share/nginx/html/index.html
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>🎥 Super YouTube Downloader</title>
    <style>
        body {
            font-family: 'Segoe UI', sans-serif;
            background: #1a1a1a;
            color: #fff;
            margin: 0;
            padding: 20px;
        }
        .container {
            max-width: 800px;
            margin: 0 auto;
            background: #2d2d2d;
            padding: 30px;
            border-radius: 10px;
            box-shadow: 0 0 20px rgba(0,0,0,0.5);
        }
        .input-group {
            margin: 20px 0;
            animation: fadeIn 0.5s;
        }
        @keyframes fadeIn {
            from { opacity: 0; transform: translateY(20px); }
            to { opacity: 1; transform: translateY(0); }
        }
        input[type="text"] {
            width: 100%;
            padding: 12px;
            border: none;
            background: #3d3d3d;
            color: #fff;
            border-radius: 5px;
            margin-bottom: 10px;
        }
        button {
            background: #4CAF50;
            color: white;
            padding: 12px 25px;
            border: none;
            border-radius: 5px;
            cursor: pointer;
            transition: all 0.3s;
        }
        button:hover {
            background: #45a049;
            transform: translateY(-2px);
        }
        .status {
            margin-top: 20px;
            padding: 10px;
            border-radius: 5px;
            background: #3d3d3d;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🎥 Super YouTube Downloader</h1>
        <div class="input-group">
            <input type="text" id="url" placeholder="ใส่ลิงก์ YouTube ที่นี่...">
            <button onclick="download()">⬇️ ดาวน์โหลด</button>
        </div>
        <div class="status" id="status"></div>
    </div>
    <script>
        async function download() {
            const url = document.getElementById('url').value;
            const status = document.getElementById('status');
            status.innerHTML = '⚡ กำลังดาวน์โหลด...';
            try {
                const response = await fetch('/download', {
                    method: 'POST',
                    headers: {'Content-Type': 'application/json'},
                    body: JSON.stringify({url})
                });
                const data = await response.json();
                status.innerHTML = `✅ ดาวน์โหลดเสร็จสิ้น: ${data.filename}`;
            } catch (error) {
                status.innerHTML = '❌ เกิดข้อผิดพลาด: ' + error;
            }
        }
    </script>
</body>
</html>
EOF

# สร้าง Flask app
cat << 'EOF' > /data/data/com.termux/files/home/app.py
from flask import Flask, request, jsonify
import subprocess
import os

app = Flask(__name__)

@app.route('/')
def home():
    return open('/data/data/com.termux/files/usr/share/nginx/html/index.html').read()

@app.route('/download', methods=['POST'])
def download():
    try:
        url = request.json['url']
        output = subprocess.check_output([
            'yt-dlp',
            '-f', 'best',
            '-o', '/sdcard/Download/%(title)s.%(ext)s',
            '--no-warnings',
            url
        ], stderr=subprocess.STDOUT)
        return jsonify({'status': 'success', 'filename': output.decode().split('\n')[-2]})
    except Exception as e:
        return jsonify({'status': 'error', 'message': str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)
EOF

# ตั้งค่า Nginx
echo "server {
    listen 8080;
    server_name localhost;
    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
}" > /data/data/com.termux/files/usr/etc/nginx/sites-enabled/default

# รีสตาร์ท Nginx
nginx -s reload

# เริ่ม SSH tunnel
echo -e "\033[36m🌐 กำลังเริ่ม SSH tunnel...\033[0m"
ssh -R 80:localhost:8080 nokey@localhost.run &

# เริ่ม Flask server
echo -e "\033[32m🚀 เริ่มต้นเซิร์ฟเวอร์...\033[0m"
python /data/data/com.termux/files/home/app.py &

# แสดงสถานะ
echo -e "\n\033[32m✨ พร้อมใช้งานแล้ว!\033[0m"
echo -e "\033[36m📱 Local URL: http://localhost:$PORT\033[0m"
echo -e "\033[36m🌍 หรือใช้ URL สาธารณะจาก SSH tunnel\033[0m"

wait
