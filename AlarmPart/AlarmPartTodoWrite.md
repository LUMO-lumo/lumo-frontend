#Alarm Folder
- 구현 기능(api명세서)
알람 API,GET,/api/alarms/{alarmId},알람 상세 조회 API====
알람 API,PUT,/api/alarms/{alarmId},알람 수정 API---------------------------------------
알람 API,DELETE,/api/alarms/{alarmId},알람 삭제 API------------------------------------
알람 API,GET,/api/alarms/{alarmId}/snooze,스누즈 설정 조회 API
알람 API,PUT,/api/alarms/{alarmId}/snooze,스누즈 설정 수정 API
알람 API,GET,/api/alarms/{alarmId}/repeat-days,반복 요일 조회 API======
알람 API,PUT,/api/alarms/{alarmId}/repeat-days,반복 요일 설정 API======
알람 API,GET,/api/alarms/{alarmId}/mission,미션 설정 조회 API=====
알람 API,PUT,/api/alarms/{alarmId}/mission,미션 설정 수정 API=====
알람 API,GET,/api/alarms,내 알람 목록 조회 API-------------------------------------------
알람 API,POST,/api/alarms,알람 생성 API------------------------------------------------
알람 API,POST,/api/alarms/{alarmId}/trigger,알람 울림 기록 API
알람 API,POST,/api/alarms/{alarmId}/missions/walk,걷기 미션 거리 업데이트 API
알람 API,POST,/api/alarms/{alarmId}/missions/submit,미션 답안 제출 API=======
알람 API,POST,/api/alarms/{alarmId}/missions/start,미션 시작 API=========
알람 API,PATCH,/api/alarms/{alarmId}/toggle,알람 ON/OFF 토글 API==========
알람 API,PATCH,/api/alarms/{alarmId}/snooze/toggle,스누즈 ON/OFF 토글 API
알람 API,GET,/api/alarms/{alarmId}/logs,특정 알람의 울림 기록 조회 API
알람 API,GET,/api/alarms/sounds,알람 사운드 목록 조회 API===========
알람 API,GET,/api/alarms/members/me/mission-history,내 미션 수행 기록 조회 API
알람 API,GET,/api/alarms/members/me/alarm-logs,내 알람 울림 기록 API

시끄러운(scream14, big thunder,  big -dog-barking , desperate shout, traimory-mega-hor   ) 
차분한( calming-melody-loop, the Island clearing, native-americas-style flute music, bell, I wish )
동기부여(. rock of joy, emperor, basic beats and bass, work hard in silence, runaway) 

{"volume":100,
"alarmTime":"01:07",
"label":"ㄴㄴ",
"snoozeSetting":{
    "maxCount":0,
    "intervalSec":0,
    "isEnabled":true
    },
"missionSetting":{
    "difficulty":"EASY",
    "missionType":"CALCULATION",
    "walkGoalMeter":0,
    "questionCount":0
    },
"repeatDays":[
    "TUE","THU","FRI"
    ],
"soundType":"DEFAULT_BELL",
"vibration":true
}


#앞으로 작업 내용물

Trigger (시작점): AlarmKit 알람이 울리고 사용자가 이를 끕니다(Dismiss).
지연 실행: 알람 종료 후 정확히 5초 뒤부터 '지옥의 루프'가 시작됩니다.
Loop (반복 알림):
간격: 5초마다 반복.
알림 내용:
Title: 설정한 알람 이름 (예: "기상").
Body: "알람을 끄려면 여기를 눌러 앱을 실행하세요."
Sound: 사용자가 설정한 사운드 재생.
Level: .timeSensitive (방해금지 모드 뚫기).
Interaction (사용자 반응):

알림 배너 클릭 -> 잠금화면 -> 잠금 해제(FaceID/Passcode) -> 앱 진입.
Mission Phase (미션 수행):
앱 진입 시 MissionView가 즉시 표시됩니다.
소리: 미션을 성공하기 전까지 알람 소리는 계속 울립니다.
성공 조건: 수학, 따라쓰기 등 미션 완료.
성공 시: 소리 중단(stopAlarmSound) 및 예약된 5초 반복 알림 전체 취소.
End Phase (브리핑):
미션 성공 직후, "오늘의 할 일 브리핑 API"를 호출.
화면에 오늘 날짜의 일정/할 일을 브리핑하며 하루를 시작.





내 알람 목록 조회    /api/alarms    GET    연결됨 (fetchAlarms)
알람 생성    /api/alarms    POST    연결됨 (addAlarm)
알람 수정    /api/alarms/{alarmId}    PUT    연결됨 (updateAlarm)
알람 삭제    /api/alarms/{alarmId}    DELETE    연결됨 (deleteAlarm)


#GET    fetchAlarmDetail
- request body

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
#PUT    updateAlarm
- request body
{
  "alarmTime": "string",
  "label": "string",
  "soundType": "string",
  "vibration": true,
  "volume": 100,
  "repeatDays": [
    "MON"
  ],
  "snoozeSetting": {
    "isEnabled": true,
    "intervalSec": 0,
    "maxCount": 0
  },
  "missionSetting": {
    "missionType": "NONE",
    "difficulty": "EASY",
    "walkGoalMeter": 0,
    "questionCount": 0
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

#DELETE    deleteAlarm
- request body

- response
{
  "code": "string",
  "message": "string",
  "result": "string",
  "success": true
}

#GET    fetchMyAlarms
- request body

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

#POST    createAlarm
- request body
{
  "alarmTime": "string",
  "label": "string",
  "isEnabled": true,
  "soundType": "string",
  "vibration": true,
  "volume": 100,
  "repeatDays": [
    "MON"
  ],
  "snoozeSetting": {
    "isEnabled": true,
    "intervalSec": 0,
    "maxCount": 0
  },
  "missionSetting": {
    "missionType": "NONE",
    "difficulty": "EASY",
    "walkGoalMeter": 0,
    "questionCount": 0
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

#PATCH    toggleAlarm
- request body

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

#GET    fetchSnoozeSettings
- request body

- response
{
  "code": "string",
  "message": "string",
  "result": {
    "snoozeId": 0,
    "isEnabled": true,
    "intervalSec": 0,
    "maxCount": 0
  },
  "success": true
}

#PUT    updateSnoozeSettings
- request body
{
  "isEnabled": true,
  "intervalSec": 0,
  "maxCount": 0
}
- response
{
  "code": "string",
  "message": "string",
  "result": {
    "snoozeId": 0,
    "isEnabled": true,
    "intervalSec": 0,
    "maxCount": 0
  },
  "success": true
}

#PATCH    toggleSnooze
- request body

- response
{
  "code": "string",
  "message": "string",
  "result": {
    "snoozeId": 0,
    "isEnabled": true,
    "intervalSec": 0,
    "maxCount": 0
  },
  "success": true
}

#GET    fetchRepeatDays
- request body

- response
{
  "code": "string",
  "message": "string",
  "result": [
    "string"
  ],
  "success": true
}
#PUT    updateRepeatDays
- request body
{
  "repeatDays": [
    "MON"
  ]
}
- response
{
  "code": "string",
  "message": "string",
  "result": [
    "string"
  ],
  "success": true
}

#GET    fetchMissionSettings
- request body

- response
{
  "code": "string",
  "message": "string",
  "result": {
    "missionType": "NONE",
    "difficulty": "EASY",
    "walkGoalMeter": 0,
    "questionCount": 0
  },
  "success": true
}

#PUT    updateMissionSettings
- request body
{
  "missionType": "NONE",
  "difficulty": "EASY",
  "walkGoalMeter": 0,
  "questionCount": 0
}
- response
{
  "code": "string",
  "message": "string",
  "result": {
    "missionType": "NONE",
    "difficulty": "EASY",
    "walkGoalMeter": 0,
    "questionCount": 0
  },
  "success": true
}
#POST    startMission
- request body

- response
{
  "code": "string",
  "message": "string",
  "result": [
    {
      "contentId": 0,
      "missionType": "NONE",
      "difficulty": "EASY",
      "question": "string",
      "answer": "string"
    }
  ],
  "success": true
}

#POST    updateWalkMissionDistance
- request body
{
  "currentDistance": 0.1
}
- response
{
  "code": "string",
  "message": "string",
  "result": {
    "goalDistance": 0,
    "currentDistance": 0.1,
    "progressPercentage": 0.1,
    "isCompleted": true
  },
  "success": true
}

#POST    submitMissionAnswer
- request body
{
  "contentId": 0,
  "userAnswer": "string",
  "attemptCount": 0
}
- response
{
  "code": "string",
  "message": "string",
  "result": {
    "isCorrect": true,
    "isCompleted": true,
    "remainingQuestions": 0,
    "message": "string"
  },
  "success": true
}
#POST    recordAlarmTrigger
- request body

- response
{
  "code": "string",
  "message": "string",
  "result": {
    "logId": 0,
    "alarmId": 0,
    "triggeredAt": "2026-02-08T15:55:32.290Z",
    "dismissedAt": "2026-02-08T15:55:32.290Z",
    "dismissType": "MISSION",
    "snoozeCount": 0
  },
  "success": true
}

#GET    fetchAlarmLogs
- request body

- response
{
  "code": "string",
  "message": "string",
  "result": [
    {
      "logId": 0,
      "alarmId": 0,
      "triggeredAt": "2026-02-08T15:56:24.182Z",
      "dismissedAt": "2026-02-08T15:56:24.182Z",
      "dismissType": "MISSION",
      "snoozeCount": 0
    }
  ],
  "success": true
}

#GET    fetchMyAlarmHistory
- request body

- response
{
  "code": "string",
  "message": "string",
  "result": [
    {
      "logId": 0,
      "alarmId": 0,
      "triggeredAt": "2026-02-08T15:56:50.918Z",
      "dismissedAt": "2026-02-08T15:56:50.918Z",
      "dismissType": "MISSION",
      "snoozeCount": 0
    }
  ],
  "success": true
}

#GET    fetchMyMissionHistory
- request body

- response
{
  "code": "string",
  "message": "string",
  "result": [
    {
      "historyId": 0,
      "alarmId": 0,
      "missionType": "NONE",
      "isSuccess": true,
      "attemptCount": 0,
      "completedAt": "2026-02-08T15:57:13.750Z"
    }
  ],
  "success": true
}

#GET    fetchAlarmSounds
- request body

- response
{
  "code": "string",
  "message": "string",
  "result": [
    {
      "soundId": "string",
      "displayName": "string",
      "isDefault": true
    }
  ],
  "success": true
}


