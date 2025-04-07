#!/bin/bash

# 🚀 ติดตั้งของเล่นกันหน่อย
echo "🔄 กำลังอัพเกรดของเล่น..."
pkg update -y && pkg install python openssh git gpsd -y

# 📂 สร้างรังให้เว็บของเรา
echo "🏗️ กำลังสร้างรังที่ localhost:8080..."
cd /data/data/com.termux/files/home || exit
[ ! -d "webapp" ] && mkdir webapp
cd webapp || exit

# 🎨 สร้างหน้าเว็บสุดเจ๋ง
cat << 'EOF' > index.html
<!DOCTYPE html>
<html lang="th">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>🛰️ แผนที่ดาวเทียม & PM2.5</title>
    <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" />
    <link rel="stylesheet" href="https://unpkg.com/@raruto/leaflet-elevation/dist/leaflet-elevation.css" />
    <style>
        body { margin: 0; font-family: 'Kanit', sans-serif; }
        #map { height: 100vh; width: 100%; }
        .info-box {
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
        .signal-meter {
            display: inline-block;
            width: 20px;
            height: 15px;
            background: linear-gradient(90deg, #f00, #ff0, #0f0);
        }
        .map-type {
            position: fixed;
            top: 10px;
            right: 10px;
            z-index: 1000;
        }
    </style>
</head>
<body>
    <div id="map"></div>
    <div class="info-box">
        <div id="gps-info">🛰️ กำลังค้นหาดาวเทียม...</div>
        <div id="pm25-info">🌫️ กำลังวัดฝุ่น PM2.5...</div>
        <div>📡 สัญญาณ: <span class="signal-meter"></span></div>
    </div>
    <div class="map-type">
        <select id="mapStyle" onchange="changeMapStyle(this.value)">
            <option value="street">🗺️ แผนที่ปกติ</option>
            <option value="satellite">🛸 ดาวเทียม</option>
            <option value="terrain">⛰️ ภูมิประเทศ</option>
            <option value="3d">🌍 3D</option>
        </select>
    </div>
    
    <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
    <script src="https://unpkg.com/@raruto/leaflet-elevation/dist/leaflet-elevation.js"></script>
    <script>
        // 🗺️ แผนที่เริ่มต้น
        var map = L.map('map', { preferCanvas: true }).setView([13.7563, 100.5018], 10);
        var currentLayer;
        
        // 🎨 สไตล์แผนที่
        const mapStyles = {
            street: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
            satellite: 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
            terrain: 'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png',
            '3d': 'https://tile.osmbuildings.org/0.2/ap-3/{z}/{x}/{y}.png'
        };

        function changeMapStyle(style) {
            if (currentLayer) map.removeLayer(currentLayer);
            currentLayer = L.tileLayer(mapStyles[style]).addTo(map);
        }
        
        // 🛰️ ดึงข้อมูล GPS
        if ("geolocation" in navigator) {
            navigator.geolocation.watchPosition(position => {
                const { latitude, longitude, accuracy } = position.coords;
                const satellites = Math.floor(Math.random() * 12) + 1; // จำลองจำนวนดาวเทียม
                const signal = Math.min(accuracy / 100, 1) * 100;
                
                document.getElementById('gps-info').innerHTML = 
                    `🛰️ ดาวเทียม: ${satellites} ดวง<br>
                     📍 พิกัด: ${latitude.toFixed(4)}, ${longitude.toFixed(4)}<br>
                     📡 ความแม่นยำ: ${accuracy.toFixed(0)}m`;

                // 🎯 อัพเดทตำแหน่งบนแผนที่
                map.setView([latitude, longitude]);
                L.circle([latitude, longitude], {
                    color: 'blue',
                    fillColor: '#30f',
                    fillOpacity: 0.2,
                    radius: accuracy
                }).addTo(map);
            });
        }

        // เริ่มต้นด้วยแผนที่ปกติ
        changeMapStyle('street');

        // 🌫️ ดึงข้อมูล PM2.5
        fetch('https://api.waqi.info/feed/here/?token=30ad392578ae9d83ce9f1bfee4fe6adcee82431c')
            .then(response => response.json())
            .then(data => {
                const pm25 = data.data.iaqi.pm25?.v || 'N/A';
                document.getElementById('pm25-info').innerHTML = 
                    `🌫️ PM2.5: ${pm25} µg/m³<br>
                     ${pm25 > 50 ? '😷 สวมหน้ากากนะจ๊ะ!' : '😊 คุณภาพอากาศดี'}`;
            })
            .catch(error => {
                document.getElementById('pm25-info').innerHTML = '❌ เกิดข้อผิดพลาด: ' + error;
            });
    </script>
</body>
</html>
EOF

# 🚀 รันเซิร์ฟเวอร์
echo "🌟 กำลังปล่อยของ..."
python -m http.server 8080 &
SERVER_PID=$!

# ⏳ รอแปป
sleep 2

# 🔄 Forward พอร์ต
echo "🔄 กำลัง Forward พอร์ต..."
ssh -R 80:localhost:8080 nokey@localhost.run &
SSH_PID=$!

# 📢 แสดงสถานะ
echo "🎉 เว็บพร้อมใช้งานแล้วที่ localhost:8080"
echo "🔧 PID เซิร์ฟเวอร์: $SERVER_PID | PID SSH: $SSH_PID"

# 🛑 จัดการปิดเซิร์ฟเวอร์
trap 'echo "👋 ลาก่อน..."; kill $SERVER_PID $SSH_PID; exit' INT

# ⏳ รอไปเรื่อยๆ
echo "💡 กด Ctrl+C เมื่อต้องการปิด"
while true; do sleep 1; done
