#!/bin/bash

# เริ่มต้นด้วยการตรวจสอบ Termux และติดตั้งเครื่องมือที่จำเป็น
echo "กำลังตรวจสอบระบบ Termux และติดตั้ง dependencies..."
pkg update -y && pkg install python openssh git -y

# ตั้งค่าเซิร์ฟเวอร์ Python SimpleHTTPServer บนพอร์ต 8080
echo "ตั้งค่าเซิร์ฟเวอร์บน localhost:8080..."
cd /data/data/com.termux/files/home || exit
if [ ! -d "webapp" ]; then mkdir webapp; fi
cd webapp || exit

# สร้างไฟล์ index.html ที่มี HTML, CSS, JS รวมอยู่ใน Bash
cat << 'EOF' > index.html
<!DOCTYPE html>
<html lang="th">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>PM 2.5 Map</title>
    <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" />
    <style>
        body { margin: 0; font-family: Arial, sans-serif; }
        #map { height: 100vh; width: 100%; }
        .dust { position: absolute; background: rgba(255, 165, 0, 0.5); border-radius: 50%; }
        .info { position: fixed; top: 10px; left: 10px; background: white; padding: 10px; z-index: 1000; }
        @media (max-width: 600px) { .info { font-size: 12px; padding: 5px; } }
    </style>
</head>
<body>
    <div id="map"></div>
    <div class="info" id="pm25-info">กำลังโหลดข้อมูล PM 2.5...</div>
    <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
    <script>
        // ตั้งค่าแผนที่ Leaflet
        var map = L.map('map').setView([13.7563, 100.5018], 10); // เริ่มที่กรุงเทพฯ
        L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
            attribution: '© OpenStreetMap contributors'
        }).addTo(map);

        // ดึงข้อมูล PM 2.5 จาก API
        fetch('https://api.waqi.info/feed/here/?token=30ad392578ae9d83ce9f1bfee4fe6adcee82431c')
            .then(response => response.json())
            .then(data => {
                let pm25 = data.data.iaqi.pm25?.v || 'N/A';
                let lat = data.data.lat || 13.7563;
                let lon = data.data.lon || 100.5018;
                document.getElementById('pm25-info').innerHTML = `PM 2.5: ${pm25} µg/m³<br>ตำแหน่ง: ${lat}, ${lon}`;

                // เพิ่ม marker บนแผนที่
                L.marker([lat, lon]).addTo(map).bindPopup(`PM 2.5: ${pm25} µg/m³`).openPopup();

                // สร้างเอฟเฟกต์ฝุ่น
                let dustSize = pm25 * 2; // ขนาดวงกลมตามค่า PM 2.5
                let dust = L.circle([lat, lon], {
                    color: 'orange',
                    fillColor: '#ff7800',
                    fillOpacity: 0.3,
                    radius: dustSize
                }).addTo(map);
            })
            .catch(error => {
                document.getElementById('pm25-info').innerHTML = 'เกิดข้อผิดพลาด: ' + error;
            });
    </script>
</body>
</html>
EOF

# รันเซิร์ฟเวอร์ Python บนพอร์ต 8080
echo "เริ่มรันเซิร์ฟเวอร์ Python บนพอร์ต 8080..."
python -m http.server 8080 &
SERVER_PID=$!

# รอ 2 วินาทีเพื่อให้เซิร์ฟเวอร์เริ่มทำงาน
sleep 2

# Forward พอร์ต 8080 ไปยังพอร์ต 80 ด้วย SSH
echo "Forward พอร์ต 8080 ไปยังพอร์ต 80 ด้วย SSH..."
ssh -R 80:localhost:8080 nokey@localhost.run &
SSH_PID=$!

# แสดงสถานะ
echo "เซิร์ฟเวอร์รันอยู่ที่ localhost:8080 และ forward ไปยังพอร์ต 80"
echo "PID เซิร์ฟเวอร์: $SERVER_PID | PID SSH: $SSH_PID"

# ฟังก์ชันสำหรับหยุดเซิร์ฟเวอร์เมื่อกด Ctrl+C
trap 'echo "หยุดเซิร์ฟเวอร์..."; kill $SERVER_PID $SSH_PID; exit' INT

# รอให้ผู้ใช้กด Ctrl+C เพื่อหยุด
echo "กด Ctrl+C เพื่อหยุดเซิร์ฟเวอร์"
while true; do
    sleep 1
done
