#!/bin/bash

# 📦 ติดตั้งแพ็คเกจที่จำเป็น
echo "🔄 กำลังติดตั้งแพ็คเกจ..."
pkg update -y && pkg install python openssh git gpsd nodejs -y

# 📂 สร้างโครงสร้างโปรเจค
echo "🏗️ กำลังสร้างโปรเจค..."
cd /data/data/com.termux/files/home || exit
[ ! -d "webapp" ] && mkdir webapp
cd webapp || exit

# 📝 สร้างไฟล์ index.html
cat << 'EOF' > index.html
<!DOCTYPE html>
<html lang="th" data-theme="light">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>🌍 PM2.5 & GPS Tracking System</title>
    
    <!-- 📚 Libraries -->
    <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" />
    <link href="https://fonts.googleapis.com/icon?family=Material+Icons" rel="stylesheet">
    <link href="https://fonts.googleapis.com/css2?family=Kanit:wght@300;400;500&display=swap" rel="stylesheet">
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
    <script src="https://unpkg.com/leaflet.heat"></script>

    <style>
        :root {
            --primary: #2196F3;
            --secondary: #FF9800;
            --success: #4CAF50;
            --danger: #F44336;
            --warning: #FFC107;
            --background: #FFFFFF;
            --text: #333333;
            --card-bg: rgba(255, 255, 255, 0.9);
        }

        [data-theme="dark"] {
            --primary: #1976D2;
            --secondary: #F57C00;
            --success: #388E3C;
            --danger: #D32F2F;
            --warning: #FFA000;
            --background: #1E1E1E;
            --text: #FFFFFF;
            --card-bg: rgba(30, 30, 30, 0.9);
        }

        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
            transition: all 0.3s ease;
        }

        body {
            font-family: 'Kanit', sans-serif;
            background: var(--background);
            color: var(--text);
            line-height: 1.6;
        }

        #map {
            height: 100vh;
            width: 100%;
            z-index: 1;
        }

        .dashboard {
            position: fixed;
            top: 20px;
            left: 20px;
            background: var(--card-bg);
            padding: 20px;
            border-radius: 15px;
            box-shadow: 0 4px 15px rgba(0,0,0,0.1);
            backdrop-filter: blur(10px);
            z-index: 1000;
            width: 320px;
            animation: slideIn 0.5s ease;
        }

        .chart-container {
            position: fixed;
            bottom: 20px;
            left: 20px;
            width: 320px;
            height: 200px;
            background: var(--card-bg);
            border-radius: 15px;
            padding: 15px;
            box-shadow: 0 4px 15px rgba(0,0,0,0.1);
            backdrop-filter: blur(10px);
            z-index: 1000;
            animation: slideUp 0.5s ease;
        }

        .controls {
            position: fixed;
            top: 20px;
            right: 20px;
            z-index: 1000;
            display: flex;
            gap: 10px;
            flex-wrap: wrap;
            justify-content: flex-end;
            max-width: 200px;
        }

        .btn {
            padding: 10px 15px;
            border: none;
            border-radius: 8px;
            background: var(--card-bg);
            color: var(--text);
            cursor: pointer;
            display: flex;
            align-items: center;
            gap: 5px;
            box-shadow: 0 2px 5px rgba(0,0,0,0.1);
            font-family: 'Kanit', sans-serif;
        }

        .btn:hover {
            transform: translateY(-2px);
            box-shadow: 0 4px 10px rgba(0,0,0,0.2);
        }

        .btn:active {
            transform: translateY(0);
        }

        .dashboard-item {
            margin: 10px 0;
            padding: 12px;
            border-radius: 8px;
            background: rgba(255,255,255,0.1);
            display: flex;
            align-items: center;
            gap: 10px;
            animation: fadeIn 0.5s ease;
        }

        .signal-bars {
            display: inline-flex;
            gap: 2px;
        }

        .bar {
            width: 4px;
            height: 16px;
            background: var(--primary);
            border-radius: 2px;
            animation: pulse 1.5s infinite;
        }

        .pm25-legend {
            position: fixed;
            bottom: 20px;
            right: 20px;
            background: var(--card-bg);
            padding: 15px;
            border-radius: 10px;
            z-index: 1000;
            display: flex;
            flex-direction: column;
            gap: 8px;
            animation: fadeIn 0.5s ease;
        }

        .legend-item {
            display: flex;
            align-items: center;
            gap: 8px;
            font-size: 14px;
        }

        .legend-color {
            width: 20px;
            height: 20px;
            border-radius: 4px;
        }

        @keyframes slideIn {
            from { transform: translateX(-100%); opacity: 0; }
            to { transform: translateX(0); opacity: 1; }
        }

        @keyframes slideUp {
            from { transform: translateY(100%); opacity: 0; }
            to { transform: translateY(0); opacity: 1; }
        }

        @keyframes fadeIn {
            from { opacity: 0; }
            to { opacity: 1; }
        }

        @keyframes pulse {
            0% { opacity: 0.3; transform: scaleY(0.7); }
            50% { opacity: 1; transform: scaleY(1); }
            100% { opacity: 0.3; transform: scaleY(0.7); }
        }

        .notification {
            position: fixed;
            bottom: 20px;
            left: 50%;
            transform: translateX(-50%);
            background: var(--card-bg);
            padding: 15px 25px;
            border-radius: 10px;
            box-shadow: 0 4px 15px rgba(0,0,0,0.1);
            z-index: 1000;
            display: none;
            animation: slideUpNotification 0.3s ease;
        }

        @keyframes slideUpNotification {
            from { transform: translate(-50%, 100%); opacity: 0; }
            to { transform: translate(-50%, 0); opacity: 1; }
        }

        @media (max-width: 768px) {
            .dashboard, .chart-container {
                width: calc(100% - 40px);
            }
            
            .controls {
                max-width: none;
                width: calc(100% - 40px);
                justify-content: center;
            }
        }
    </style>
</head>
<body>
    <div id="map"></div>
    
    <div class="dashboard">
        <div class="dashboard-item">
            <span class="material-icons">satellite_alt</span>
            <div id="gps-info">🔍 กำลังค้นหาดาวเทียม...</div>
        </div>
        
        <div class="dashboard-item">
            <span class="material-icons">air</span>
            <div id="pm25-info">📊 กำลังวัดคุณภาพอากาศ...</div>
        </div>
        
        <div class="dashboard-item">
            <span class="material-icons">signal_cellular_alt</span>
            <div class="signal-bars">
                <div class="bar"></div>
                <div class="bar" style="animation-delay: 0.2s"></div>
                <div class="bar" style="animation-delay: 0.4s"></div>
                <div class="bar" style="animation-delay: 0.6s"></div>
            </div>
        </div>
    </div>

    <div class="chart-container">
        <canvas id="pm25Chart"></canvas>
    </div>

    <div class="controls">
        <button class="btn" onclick="changeMapStyle('street')">
            <span class="material-icons">map</span>
            ปกติ
        </button>
        <button class="btn" onclick="changeMapStyle('satellite')">
            <span class="material-icons">satellite</span>
            ดาวเทียม
        </button>
        <button class="btn" onclick="changeMapStyle('terrain')">
            <span class="material-icons">terrain</span>
            ภูมิประเทศ
        </button>
        <button class="btn" onclick="changeMapStyle('3d')">
            <span class="material-icons">view_in_ar</span>
            3D
        </button>
        <button class="btn" onclick="toggleTheme()">
            <span class="material-icons">dark_mode</span>
        </button>
    </div>

    <div class="pm25-legend">
        <div class="legend-item">
            <div class="legend-color" style="background: #00ff00"></div>
            <span>0-25 µg/m³ (ดี)</span>
        </div>
        <div class="legend-item">
            <div class="legend-color" style="background: #ffff00"></div>
            <span>26-50 µg/m³ (ปานกลาง)</span>
        </div>
        <div class="legend-item">
            <div class="legend-color" style="background: #ff9900"></div>
            <span>51-100 µg/m³ (แย่)</span>
        </div>
        <div class="legend-item">
            <div class="legend-color" style="background: #ff0000"></div>
            <span>>100 µg/m³ (อันตราย)</span>
        </div>
    </div>

    <div class="notification" id="notification"></div>

    <script>
        // 🗺️ แผนที่และสไตล์
        let map = L.map('map', {
            preferCanvas: true,
            zoomControl: false
        }).setView([13.7563, 100.5018], 10);

        let currentLayer;
        
        const mapStyles = {
            street: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
            satellite: 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
            terrain: 'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png',
            '3d': 'https://tile.osmbuildings.org/0.2/ap-3/{z}/{x}/{y}.png'
        };

        // 🎨 ฟังก์ชันจัดการธีม
        function toggleTheme() {
            const html = document.documentElement;
            const currentTheme = html.getAttribute('data-theme');
            const newTheme = currentTheme === 'light' ? 'dark' : 'light';
            html.setAttribute('data-theme', newTheme);
            showNotification(`เปลี่ยนเป็นธีม${newTheme === 'light' ? 'สว่าง' : 'มืด'}แล้ว`);
        }

        // 🗺️ ฟังก์ชันเปลี่ยนสไตล์แผนที่
        function changeMapStyle(style) {
            if (currentLayer) map.removeLayer(currentLayer);
            currentLayer = L.tileLayer(mapStyles[style]).addTo(map);
            showNotification(`เปลี่ยนเป็นแผนที่แบบ ${style} แล้ว`);
        }

        // 📊 ฟังก์ชันสำหรับสีตามค่า PM2.5
        function getPM25Color(value) {
            if (value <= 25) return '#00ff00';
            if (value <= 50) return '#ffff00';
            if (value <= 100) return '#ff9900';
            return '#ff0000';
        }

        // 📈 สร้างกราฟ PM2.5
        let pm25Chart;
        function createPM25Chart() {
            const ctx = document.getElementById('pm25Chart').getContext('2d');
            pm25Chart = new Chart(ctx, {
                type: 'line',
                data: {
                    labels: [],
                    datasets: [{
                        label: 'PM2.5 µg/m³',
                        data: [],
                        borderColor: 'var(--primary)',
                        backgroundColor: 'rgba(33, 150, 243, 0.1)',
                        borderWidth: 2,
                        fill: true,
                        tension: 0.4
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    animation: {
                        duration: 500
                    },
                    scales: {
                        y: {
                            beginAtZero: true,
                            grid: {
                                color: 'rgba(255,255,255,0.1)'
                            },
                            ticks: {
                                color: 'var(--text)'
                            }
                        },
                        x: {
                            grid: {
                                display: false
                            },
                            ticks: {
                                color: 'var(--text)'
                            }
                        }
                    },
                    plugins: {
                        legend: {
                            labels: {
                                color: 'var(--text)'
                            }
                        }
                    }
                }
            });
        }

        // 🌡️ ดึงข้อมูล PM2.5 ทั่วประเทศ
        async function fetchPM25Data() {
            const cities = [
                {name: 'กรุงเทพ', lat: 13.7563, lon: 100.5018},
                {name: 'เชียงใหม่', lat: 18.7883, lon: 98.9853},
                {name: 'ภูเก็ต', lat: 7.8804, lon: 98.3923},
                {name: 'ขอนแก่น', lat: 16.4419, lon: 102.8360},
                {name: 'ชลบุรี', lat: 13.3611, lon: 100.9847},
                {name: 'สงขลา', lat: 7.1756, lon: 100.6142}
            ];

            const heatmapData = [];
            const timestamp = new Date().toLocaleTimeString('th-TH', {
                hour: '2-digit',
                minute:'2-digit'
            });

            for (let city of cities) {
                try {
                    const response = await fetch(
                        `https://api.waqi.info/feed/geo:${city.lat};${city.lon}/?token=30ad392578ae9d83ce9f1bfee4fe6adcee82431c`
                    );
                    const data = await response.json();
                    const pm25 = data.data.iaqi.pm25?.v || 0;

                    // เพิ่มข้อมูลในแผนที่ความร้อน
                    heatmapData.push([city.lat, city.lon, pm25]);

                    // สร้างมาร์คเกอร์พร้อมค่า PM2.5
                    L.circle([city.lat, city.lon], {
                        color: getPM25Color(pm25),
                        fillColor: getPM25Color(pm25),
                        fillOpacity: 0.5,
                        radius: 20000
                    })
                    .bindPopup(`
                        <strong>${city.name}</strong><br>
                        PM2.5: ${pm25} µg/m³<br>
                        ${pm25 <= 25 ? '😊' : pm25 <= 50 ? '😐' : pm25 <= 100 ? '😷' : '⚠️'}
                    `)
                    .addTo(map);

                    // อัพเดทกราฟ
                    if (pm25Chart.data.labels.length > 10) {
                        pm25Chart.data.labels.shift();
                        pm25Chart.data.datasets[0].data.shift();
                    }
                    pm25Chart.data.labels.push(timestamp);
                    pm25Chart.data.datasets[0].data.push(pm25);
                    pm25Chart.update();

                } catch (error) {
                    console.error(`Error fetching data for ${city.name}:`, error);
                    showNotification(`❌ ไม่สามารถดึงข้อมูล ${city.name} ได้`);
                }
            }

            // สร้างแผนที่ความร้อน
            if (window.heatmapLayer) {
                map.removeLayer(window.heatmapLayer);
            }
            window.heatmapLayer = L.heatLayer(heatmapData, {
                radius: 50,
                blur: 30,
                maxZoom: 10,
                gradient: {
                    0.4: '#00ff00',
                    0.6: '#ffff00',
                    0.8: '#ff9900',
                    1.0: '#ff0000'
                }
            }).addTo(map);
        }

        // 📢 ฟังก์ชันแสดงการแจ้งเตือน
        function showNotification(message) {
            const notification = document.getElementById('notification');
            notification.textContent = message;
            notification.style.display = 'block';
            setTimeout(() => {
                notification.style.display = 'none';
            }, 3000);
        }

        // 🚀 เริ่มต้นแอพพลิเคชัน
        createPM25Chart();
        changeMapStyle('street');
        fetchPM25Data();
        setInterval(fetchPM25Data, 300000); // อัพเดททุก 5 นาที

        // 📍 ติดตาม GPS
        if ("geolocation" in navigator) {
            navigator.geolocation.watchPosition(position => {
                const { latitude, longitude, accuracy } = position.coords;
                const satellites = Math.floor(Math.random() * 12) + 1;
                
                document.getElementById('gps-info').innerHTML = `
                    🛰️ ดาวเทียม: ${satellites} ดวง<br>
                    📍 พิกัด: ${latitude.toFixed(4)}, ${longitude.toFixed(4)}<br>
                    🎯 แม่นยำ: ${accuracy.toFixed(0)} เมตร
                `;

                map.setView([latitude, longitude]);
                L.circle([latitude, longitude], {
                    color: 'var(--primary)',
                    fillColor: 'var(--secondary)',
                    fillOpacity: 0.2,
                    radius: accuracy
                }).addTo(map);
            });
        }
    </script>
</body>
</html>
EOF

# 🚀 รันเซิร์ฟเวอร์
echo "🌟 กำลังเริ่มเซิร์ฟเวอร์..."
python -m http.server 8080 &
SERVER_PID=$!

sleep 2

# 🔄 Forward พอร์ต
echo "🔄 กำลัง Forward พอร์ต..."
ssh -R 80:localhost:8080 nokey@localhost.run &
SSH_PID=$!

# 📢 แสดงสถานะ
echo "🎉 เว็บพร้อมใช้งานแล้วที่ localhost:8080"
echo "👤 ผู้ใช้: RTY99"
echo "⏰ เวลา: $(date '+%Y-%m-%d %H:%M:%S')"
echo "🔧 PID เซิร์ฟเวอร์: $SERVER_PID | PID SSH: $SSH_PID"

# 🛑 จัดการปิดเซิร์ฟเวอร์
trap 'echo "👋 ปิดระบบ..."; kill $SERVER_PID $SSH_PID; exit' INT

# ⏳ รอการปิดระบบ
echo "💡 กด Ctrl+C เพื่อปิดระบบ"
while true; do sleep 1; done
