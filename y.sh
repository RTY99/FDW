#!/bin/bash

# 🔥 เริ่มต้นด้วยการตั้งค่าระบบ Termux สุดเทพ!
echo "📱 กำลังเริ่มระบบ Termux แบบจัดหนัก..."
pkg update -y && pkg install python openssh git -y

# 🎯 ตั้งค่าเซิร์ฟเวอร์ Python แบบไม่ต้องง้อใคร
echo "🚀 ตั้งค่าเซิร์ฟเวอร์บน localhost:8080..."
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
    <title>🛰️ แผนที่ PM2.5 + GPS + ฝน แบบเทพๆ</title>
    <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" />
    <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
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
        .graph-container {
            position: fixed;
            bottom: 20px;
            right: 20px;
            width: 300px;
            background: rgba(0,0,0,0.8);
            padding: 15px;
            border-radius: 10px;
            z-index: 1000;
        }
        canvas {
            background: rgba(255,255,255,0.9);
            border-radius: 5px;
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
        .time-selector {
            position: fixed;
            top: 80px;
            right: 10px;
            z-index: 1000;
            background: rgba(0,0,0,0.8);
            padding: 10px;
            border-radius: 10px;
            color: white;
        }
        .rain-info {
            position: fixed;
            top: 150px;
            right: 10px;
            z-index: 1000;
            background: rgba(0,0,0,0.8);
            padding: 10px;
            border-radius: 10px;
            color: white;
        }
    </style>
</head>
<body>
    <div id="map"></div>
    <div class="info" id="pm25-info">⚡ กำลังโหลดข้อมูล PM 2.5...</div>
    <div class="graph-container">
        <canvas id="pm25Chart"></canvas>
    </div>
    <div class="map-types">
        <button onclick="changeMapType('default')">🗺️ แผนที่ปกติ</button>
        <button onclick="changeMapType('satellite')">🛰️ ดาวเทียม</button>
        <button onclick="changeMapType('terrain')">⛰️ ภูมิประเทศ</button>
        <button onclick="changeMapType('3d')">🌍 3 มิติ</button>
    </div>
    <div class="time-selector">
        <select id="timeRange" onchange="updateChart()">
            <option value="hour">⏰ รายชั่วโมง</option>
            <option value="day">📅 รายวัน</option>
            <option value="week">📊 รายสัปดาห์</option>
        </select>
    </div>
    <div class="rain-info" id="rainInfo">
        🌧️ กำลังโหลดข้อมูลฝน...
    </div>
    <script>
        // 🗺️ ตั้งค่าแผนที่
        var map = L.map('map').setView([13.7563, 100.5018], 10);
        var currentLayer;
        var rainMarkers = L.layerGroup();
        var pm25Data = [];
        var chart;

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
            rainMarkers.addTo(map);
        }

        // 📊 สร้างกราฟ
        function createChart() {
            const ctx = document.getElementById('pm25Chart').getContext('2d');
            chart = new Chart(ctx, {
                type: 'line',
                data: {
                    labels: [],
                    datasets: [{
                        label: 'PM2.5 (µg/m³)',
                        data: [],
                        borderColor: '#4CAF50',
                        tension: 0.1
                    }]
                },
                options: {
                    responsive: true,
                    plugins: {
                        title: {
                            display: true,
                            text: '📊 ค่า PM2.5 ตามเวลา',
                            color: '#000'
                        }
                    },
                    scales: {
                        y: {
                            beginAtZero: true,
                            ticks: { color: '#000' }
                        },
                        x: {
                            ticks: { color: '#000' }
                        }
                    }
                }
            });
        }

        // 🔄 อัพเดทกราฟ
        function updateChart() {
            const timeRange = document.getElementById('timeRange').value;
            const now = new Date();
            const labels = [];
            const data = [];

            switch(timeRange) {
                case 'hour':
                    for(let i = 0; i < 24; i++) {
                        labels.push(\`\${23-i}:00\`);
                        data.push(Math.floor(Math.random() * 100));
                    }
                    break;
                case 'day':
                    for(let i = 0; i < 7; i++) {
                        const date = new Date(now);
                        date.setDate(date.getDate() - i);
                        labels.push(date.toLocaleDateString('th-TH'));
                        data.push(Math.floor(Math.random() * 100));
                    }
                    break;
                case 'week':
                    for(let i = 0; i < 4; i++) {
                        labels.push(\`สัปดาห์ที่ \${4-i}\`);
                        data.push(Math.floor(Math.random() * 100));
                    }
                    break;
            }

            chart.data.labels = labels.reverse();
            chart.data.datasets[0].data = data.reverse();
            chart.update();
        }

        // 🌧️ จำลองข้อมูลฝน
        function simulateRainData() {
            const rainLocations = [
                { lat: 13.7563, lon: 100.5018, intensity: '🌧️ หนัก' },
                { lat: 13.8000, lon: 100.5500, intensity: '🌦️ ปานกลาง' },
                { lat: 13.7200, lon: 100.4800, intensity: '🌧️ เล็กน้อย' }
            ];

            rainMarkers.clearLayers();
            let rainInfo = '🌧️ พื้นที่ฝนตก:<br>';

            rainLocations.forEach(loc => {
                const marker = L.marker([loc.lat, loc.lon], {
                    icon: L.divIcon({
                        html: '🌧️',
                        className: 'rain-marker'
                    })
                });
                marker.bindPopup(\`ฝนตก\${loc.intensity}\`);
                rainMarkers.addLayer(marker);
                rainInfo += \`- \${loc.lat.toFixed(4)}, \${loc.lon.toFixed(4)}: \${loc.intensity}<br>\`;
            });

            document.getElementById('rainInfo').innerHTML = rainInfo;
        }

        // 🚀 เริ่มต้นแอป
        changeMapType('default');
        createChart();
        updateChart();
        simulateRainData();
        setInterval(simulateRainData, 300000); // อัพเดททุก 5 นาที

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
                    \`\${quality} PM 2.5: \${pm25} µg/m³<br>
                     🎯 ตำแหน่ง: \${lat}, \${lon}\`;

                L.marker([lat, lon]).addTo(map)
                    .bindPopup(\`\${quality} PM 2.5: \${pm25} µg/m³\`)
                    .openPopup();

                pm25Data.push({
                    value: pm25,
                    timestamp: new Date()
                });
            })
            .catch(error => {
                document.getElementById('pm25-info').innerHTML = '❌ เกิดข้อผิดพลาด: ' + error;
            });
    </script>
</body>
</html>
EOF

# 🚀 รันเซิร์ฟเวอร์ Python
echo "🎮 เริ่มเซิร์ฟเวอร์ Python port 8080..."
python -m http.server 8080 &
SERVER_PID=$!

sleep 2

# 🔄 Forward พอร์ต
echo "🔗 Forward port..."
ssh -R 80:localhost:8080 nokey@localhost.run &
SSH_PID=$!

# 📢 แสดงสถานะ
echo "🎉 เซิร์ฟเวอร์พร้อมใช้งานแล้ว!"
echo "🤖 PID เซิร์ฟเวอร์: $SERVER_PID | 🔌 PID SSH: $SSH_PID"

trap 'echo "👋 ลาก่อน! หยุดเซิร์ฟเวอร์..."; kill $SERVER_PID $SSH_PID; exit' INT

echo "⌨️ กด Ctrl+C เมื่อต้องการปิดเซิร์ฟเวอร์"
while true; do
    sleep 1
done
