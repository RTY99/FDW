#!/data/data/com.termux/files/usr/bin/bash

# ตั้งค่าพื้นฐานและตรวจสอบ Termux
echo "กำลังตรวจสอบระบบ Termux และตั้งค่าเซิร์ฟเวอร์..."
pkg update -y && pkg upgrade -y
pkg install python ffmpeg nginx openssh -y
pip install yt-dlp flask

# ตัวแปรสำหรับพอร์ตและไดเรกทอรี
PORT=8080
DOWNLOAD_DIR="/sdcard/Download"
mkdir -p "$DOWNLOAD_DIR"
termux-setup-storage

# สร้างไฟล์ HTML สำหรับหน้าเว็บ
cat << 'EOF' > /data/data/com.termux/files/usr/share/nginx/html/index.html
<!DOCTYPE html><html><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0"><title>YouTube Downloader</title><style>body{font-family: Arial, sans-serif; text-align: center; padding: 20px;}input,button{padding: 10px; margin: 5px;}</style></head><body><h1>ดาวน์โหลดวิดีโอ YouTube</h1><input type="text" id="url" placeholder="ใส่ URL YouTube"><br><select id="resolution"><option value="best">ความคมชัดสูงสุด</option><option value="720p">720p</option><option value="480p">480p</option><option value="360p">360p</option></select><br><button onclick="download()">ดาวน์โหลด</button><p id="status"></p><script>function download(){let url=document.getElementById('url').value;let res=document.getElementById('resolution').value;fetch('/download?url='+encodeURIComponent(url)+'&res='+res).then(res=>res.text()).then(data=>document.getElementById('status').innerHTML=data);}</script></body></html>
EOF

# สร้าง Flask app ในไฟล์ Python
cat << 'EOF' > /data/data/com.termux/files/home/app.py
from flask import Flask, request; import subprocess; app = Flask(__name__); @app.route('/') def home(): return open('/data/data/com.termux/files/usr/share/nginx/html/index.html').read(); @app.route('/download') def download(): url = request.args.get('url'); res = request.args.get('res'); cmd = f"yt-dlp -f 'bestvideo[height<={res[:-1] if res != 'best' else ''}]+bestaudio/best' -o '/sdcard/Download/%(title)s.%(ext)s' {url}"; subprocess.run(cmd, shell=True); return 'ดาวน์โหลดสำเร็จ! ไฟล์อยู่ใน Download'; if __name__ == '__main__': app.run(host='0.0.0.0', port=8080)
EOF

# ร# ตั้งค่า Nginx และ SSH tunneling
echo "server { listen 8080; server_name localhost; location / { proxy_pass http://127.0.0.1:8080; } }" > /data/data/com.termux/files/usr/etc/nginx/sites-enabled/default
nginx -s reload
ssh -R 80:localhost:8080 nokey@localhost.run &

# เริ่มเซิร์ฟเวอร์
echo "เซิร์ฟเวอร์เริ่มทำงานที่ http://localhost:$PORT"
python /data/data/com.termux/files/home/app.py &

# รอให้เซิร์ฟเวอร์ทำงาน
sleep 2
echo "พร้อมใช้งาน! เข้าไปที่ http://localhost:$PORT หรือใช้ URL สาธารณะจาก SSH tunnel"
wait
