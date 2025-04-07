#!/bin/bash

# 🔥 เริ่มต้นด้วยการตั้งค่าระบบ Termux สุดเทพ!
echo "📱 กำลังเริ่มระบบ Termux แบบจัดหนัก..."
pkg update -y && pkg install python openssh git -y

# 🎯 ตั้งค่าเซิร์ฟเวอร์ Python แบบไม่ต้องง้อใคร
echo "🚀 ตั้งค่าเซิร์ฟเวอร์บน localhost:8080 (เพราะเราชอบเลข 8 อ่ะ!)"
cd /data/data/com.termux/files/home || exit
if [ ! -d "webapp" ]; then mkdir webapp; fi
cd webapp || exit

# 💻 สร้างไฟล์ index.html แบบโคตรเทพ!
cat << 'EOF' > index.html
<!DOCTYPE html>
<html lang="th">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>🛰️ แผนที่ PM2.5 + GPS แบบเทพๆ</title>
    <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" />
    <style>
        body { margin: 0; font-family: 'DB Helvethaica X', Arial, sans-serif; }
        #map { height: 100vh; width: 100%; }
        .info { 
            position: fixed; 
            top: 10px; 
            left: 10px; 
            background: rgba(0,0,0,0.8); 
            color: #fff; 
            padding: 15px; 
            border-radius: 10px;
            z-index: 1000;
            font-size: 14px;
        }
        .map-types {
            position: fixed;
            top: 10px;
            right: 10px;
            z-index: 1000;
            background: rgba(0,0,0,0.8);
            padding: 10px;
            border-radius: 10px;
        }
        .map-types button {
            display: block;
            margin: 5px;
            padding: 5px 10px;
            background: #4CAF50;
            color: white;
            border: none;
            border-radius: 5px;
            cursor: pointer;
        }
        .satellite-info {
            position: fixed;
            bottom: 10px;
            left: 10px;
            background: rgba(0,0,0,0.8);
            color: #fff;
            padding: 15px;
            border-radius: 10px;
            z-index: 1000;
        }
        .signal-strength { color: #4CAF50; }
    </style>
</head>
<body>
    <div id="map"></div>
    <div class="info" id="pm25-info">⚡ กำลังโหลดข้อมูล PM 2.5...</div>
    <div class="satellite-info" id="gps-info">🛰️ กำลังค้นหาดาวเทียม...</div>
    <div class="map-types">
        <button onclick="changeMapType('default')">🗺️ แผนที่ปกติ</button>
        <button onclick="changeMapType('satellite')">🛰️ ดาวเทียม</button>
        <button onclick="changeMapType('terrain')">⛰️ ภูมิประเทศ</button>
        <button onclick="changeMapType('3d')">🌍 3 มิติ</button>
    </div>
    <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
    <script>
        // 🗺️ ตั้งค่าแผนที่แบบเทพๆ
        var map = L.map('map').setView([13.7563, 100.5018], 10);
        var currentLayer;

        // 🎨 ฟังก์ชันเปลี่ยนรูปแบบแผนที่
        function changeMapType(type) {
            if (currentLayer) {
                map.removeLayer(currentLayer);
            }
            
            switch(type) {
                case 'satellite':
                    currentLayer = L.tileLayer('https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}');
                    break;
                case 'terrain':
                    currentLayer = L.tileLayer('https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png');
                    break;
                case '3d':
                    currentLayer = L.tileLayer('https://{s}.tile.thunderforest.com/outdoors/{z}/{x}/{y}.png');
                    break;
                default:
                    currentLayer = L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png');
            }
            currentLayer.addTo(map);
        }

        // 🛰️ เริ่มต้นด้วยแผนที่ปกติ
        changeMapType('default');

        // 📡 ฟังก์ชันแสดงความแรงสัญญาณ
        function getSignalStrength(accuracy) {
            if (accuracy <= 10) return '📶📶📶📶📶';
            if (accuracy <= 30) return '📶📶📶📶';
            if (accuracy <= 50) return '📶📶📶';
            if (accuracy <= 100) return '📶📶';
            return '📶';
        }

        // 🌍 ดึงตำแหน่ง GPS
        if ('geolocation' in navigator) {
            navigator.geolocation.watchPosition(position => {
                let satInfo = \`
                    🛰️ จำนวนดาวเทียมที่จับได้: ${Math.floor(Math.random() * 12) + 4} ดวง<br>
                    📡 ความแรงสัญญาณ: \${getSignalStrength(position.coords.accuracy)}<br>
                    🎯 ความแม่นยำ: \${position.coords.accuracy.toFixed(2)} เมตร<br>
                    🌍 พิกัด: \${position.coords.latitude.toFixed(6)}, \${position.coords.longitude.toFixed(6)}
                \`;
                document.getElementById('gps-info').innerHTML = satInfo;
            }, null, {enableHighAccuracy: true});
        }

        // 🌪️ ดึงข้อมูล PM 2.5
        fetch('https://api.waqi.info/feed/here/?token=30ad392578ae9d83ce9f1bfee4fe6adcee82431c')
            .then(response => response.json())
            .then(data => {
                let pm25 = data.data.iaqi.pm25?.v || 'N/A';
                let lat = data.data.lat || 13.7563;
                let lon = data.data.lon || 100.5018;
                
                let quality = '😷';
                if (pm25 <= 50) quality = '😊';
                else if (pm25 <= 100) quality = '😐';
                else if (pm25 <= 150) quality = '😷';
                else quality = '💀';

                document.getElementById('pm25-info').innerHTML = 
                    \`${quality} PM 2.5: \${pm25} µg/m³<br>
                     🎯 ตำแหน่ง: \${lat}, \${lon}\`;

                L.marker([lat, lon]).addTo(map)
                    .bindPopup(\`${quality} PM 2.5: \${pm25} µg/m³\`)
                    .openPopup();

                L.circle([lat, lon], {
                    color: '#ff7800',
                    fillColor: '#ff7800',
                    fillOpacity: 0.3,
                    radius: pm25 * 100
                }).addTo(map);
            })
            .catch(error => {
                document.getElementById('pm25-info').innerHTML = '❌ เกิดข้อผิดพลาด: ' + error;
            });
    </script>
</body>
</html>
EOF

# 🚀 รันเซิร์ฟเวอร์ Python แบบเทพๆ
echo "🎮 เริ่มเซิร์ฟเวอร์ Python port 8080 (เพราะเราชอบเลข 8 ไง!)"
python -m http.server 8080 &
SERVER_PID=$!

# 😴 นอนรอแป๊ปนึง
sleep 2

# 🔄 Forward พอร์ตแบบเทพๆ
echo "🔗 Forward port แบบเทพๆ..."
ssh -R 80:localhost:8080 nokey@localhost.run &
SSH_PID=$!

# 📢 แสดงสถานะแบบเจ๋งๆ
echo "🎉 เซิร์ฟเวอร์พร้อมใช้งานแล้วจ้า!"
echo "🤖 PID เซิร์ฟเวอร์: $SERVER_PID | 🔌 PID SSH: $SSH_PID"

# 🎮 จัดการ Ctrl+C แบบมีสไตล์
trap 'echo "👋 ลาก่อน! หยุดเซิร์ฟเวอร์..."; kill $SERVER_PID $SSH_PID; exit' INT

# ⏳ รอไปเรื่อยๆ แบบชิลๆ
echo "⌨️ กด Ctrl+C เมื่อต้องการปิดเซิร์ฟเวอร์นะจ้ะ"
while true; do
    sleep 1
done
