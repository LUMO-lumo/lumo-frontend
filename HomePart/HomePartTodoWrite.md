# Home folder
- 구현 기능

#Post 할 일 생성
- request body
{
  "eventDate": "2025-01-01",
  "content": "쓰레기 버리기"
}

- response 
{
  "code": "string",
  "message": "string",
  "result": {
    "id": 1,
    "content": "쓰레기 버리기",
    "eventDate": "2025-01-01"
  },
  "success": true
}

#Patch 할 일 수정
- reponse
{
  "code": "string",
  "message": "string",
  "result": {
    "id": 1,
    "content": "쓰레기 버리기",
    "eventDate": "2025-01-01"
  },
  "success": true
}

#Delete 할 일 삭제
- response
{
  "code": "string",
  "message": "string",
  "result": "string",
  "success": true
}

#Get 일별 할 목록 조회
-response
{
  "code": "string",
  "message": "string",
  "result": [
    {
      "id": 1,
      "content": "쓰레기 버리기",
      "eventDate": "2025-01-01"
    }
  ],
  "success": true
}


#Get 홈 페이지
- response
{
  "code": "string",
  "message": "string",
  "result": {
    "encouragement": "string",
    "todo": [
      "string"
    ],
    "missionRecord": {
      "missionSuccessRate": 0,
      "consecutiveSuccessCnt": 0
    }
  },
  "success": true
}


