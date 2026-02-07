#Alarm Folder
- 구현 기능(api명세서)
알람 생성
내 알람 목록 조회
알람 상세 조회
알람 수정 (시간, 라벨, 사운드, 음량 등)
알람 삭제
알람 ON/OFF 토글
반복 요일 조회
반복 요일 설정 (전체 교체)
스누즈 설정 조회
스누즈 설정 수정 (간격, 횟수)
스누즈 ON/OFF 토글
미션 설정 조회
미션 설정 수정 (유형, 난이도, 문제수)
미션 문제 랜덤 조회 (type, difficulty, count)
미션 문제 등록
미션 문제 삭제
미션 시작 (문제 받기)
미션 답안 제출 (정답 확인)
걷기 미션 거리 업데이트
내 미션 수행 기록 조회
특정 알람의 미션 기록 조회
내 알람 울림 기록 조회
특정 알람의 울림 기록 조회
알람 울림 기록 (앱에서 호출)
알람 해제 기록 (미션완료/스누즈/수동)


#Post: 알람 생성 API
/api/alarms
- request body
{
  "alarmTime": "07:00",
  "label": "출근 알람",
  "isEnabled": true,
  "soundType": "차분한",
  "vibration": true,
  "volume": 70,
  "repeatDays": ["MON", "TUE", "WED", "THU", "FRI"],
  "snoozeSetting": {
    "isEnabled": true,
    "intervalSec": 300,
    "maxCount": 3
  }
}

- response
{
  "code": "string",
  "message": "string",
  "result": {
    "alarmId": 0,
    "alarmTime": "string",
    "label": "string",
    "isEnabled": true,
    "soundType": "string",
    "vibration": true,
    "volume": 0,
    "repeatDays": [
      "MON"
    ],
    "snoozeSetting": {
      "snoozeId": 0,
      "isEnabled": true,
      "intervalSec": 0,
      "maxCount": 0
    }
  },
  "success": true
}

#Get: 내 알람 목록 조회 API
- request body
{
  "code": "string",
  "message": "string",
  "result": [
    {
      "alarmId": 0,
      "alarmTime": "string",
      "label": "string",
      "isEnabled": true,
      "soundType": "string",
      "vibration": true,
      "volume": 0,
      "repeatDays": [
        "MON"
      ],
      "snoozeSetting": {
        "snoozeId": 0,
        "isEnabled": true,
        "intervalSec": 0,
        "maxCount": 0
      }
    }
  ],
  "success": true
}

- response
{
  "code": "string",
  "message": "string",
  "result": [
    {
      "alarmId": 0,
      "alarmTime": "string",
      "label": "string",
      "isEnabled": true,
      "soundType": "string",
      "vibration": true,
      "volume": 0,
      "repeatDays": [
        "MON"
      ],
      "snoozeSetting": {
        "snoozeId": 0,
        "isEnabled": true,
        "intervalSec": 0,
        "maxCount": 0
      }
    }
  ],
  "success": true
}


# Get: 알람 상세 조회 API--> 알람 수정하는 파트를 염두하고 개발
- request body
{
  "code": "string",
  "message": "string",
  "result": {
    "alarmId": 0,
    "alarmTime": "string",
    "label": "string",
    "isEnabled": true,
    "soundType": "string",
    "vibration": true,
    "volume": 0,
    "repeatDays": [
      "MON"
    ],
    "snoozeSetting": {
      "snoozeId": 0,
      "isEnabled": true,
      "intervalSec": 0,
      "maxCount": 0
    }
  },
  "success": true
}

- response


