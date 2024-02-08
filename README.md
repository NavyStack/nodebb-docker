# nodebb-docker

## Simple Start

```bash
git clone https://github.com/NavyStack/nodebb-docker.git
```

```bash
cd nodebb-docker
```

```bash
mkdir -p ./data/
```

1. `nodebb-mongo-init.js`
2. `setup.json`
3. `docker-compose.yml`

- 필요한 부분 올바르게 수정: DB 혹은 도메인 등
- 권한 문제로 도커 볼륨 활용함. ( UID 1001 , PID 1001 )

**MIT 라이선스에 따라 필요하면 사용자가 직접 수정 '있는 그대로' 제공됩니다.**

- 온몸 비틀기한 결과임. 왜 WebGUI에서 입력된 값이 반영되지 않고, 하드코딩된 `setup.json`이 사용되는지는 저도 모릅니다.
- 그래서 간편하게 `setup.json`를 수정해서 마운트 하고 WebUI로 진행하세요.
- 마찬가지로 PGsql도 DB사용자와 PASSWORD를 올바르게 설정해도 자꾸 하드코딩된 값으로 시도해서 로그에 남음.....
- Docker를 고려하지 않고 설계 했을 가능성이 높음.
- 원본에 PR하고 싶으나, 엄두가 나지 않습니다.....

관련된 파일은 ./data/에 옹기종기 모아서 이동이 쉽게함.

## 라이선스

모든 Docker 이미지와 마찬가지로, 여기에는 다른 라이선스(예: 기본 배포판의 Bash 등 및 포함된 기본 소프트웨어의 직간접적인 종속성)가 적용되는 다른 소프트웨어도 포함될 수 있습니다.

사전 빌드된 이미지 사용과 관련하여, 이 이미지를 사용할 때 이미지에 포함된 모든 소프트웨어에 대한 관련 라이선스를 준수하는지 확인하는 것은 이미지 사용자의 책임입니다.

기타 모든 상표는 각 소유주의 재산이며, 달리 명시된 경우를 제외하고 본문에서 언급한 모든 상표 소유자 또는 기타 업체와의 제휴관계, 홍보 또는 연관관계를 주장하지 않습니다.
