# 세션 00: 개발 환경 설정

## Azure OpenAI 프록시 구독 및 GitHub Copilot 구독 신청

1. 아래 링크를 클릭해서 Azure OpenAI 프록시 구독 및 GitHub Copilot 구독을 신청합니다.

   👉 구독 신청 링크: [https://aka.ms/aspireinadaykr/apply](https://aka.ms/aspireinadaykr/apply)

1. 신청한 이메일을 통해 `DoNotReply@aoai.kr` 발신자로 Azure OpenAI 프록시 구독 코드 및 GitHub Copilot 구독 코드가 온 것을 확인합니다.
1. 아래 링크를 통해 GitHub Copilot 구독을 마무리합니다.

   👉 GitHub Copilot 구독 신청 링크: [https://github.com/redeem](https://github.com/redeem)

1. 아래 링크를 통해 Azure OpenAI 프록시 코드가 제대로 작동하는지 확인합니다.

   👉 Azure OpenAI 프록시 플레이그라운드 링크: [https://proxy.aoai.kr/playground](https://proxy.aoai.kr/playground)

## GitHub Codespaces 시작

1. 이 리포지토리를 자신의 GitHub 계정으로 포크합니다.
1. 포크한 리포지토리에서 GitHub Codespaces 인스턴스를 생성합니다.

   ![GitHub Codespaces 인스턴스 생성하기](./images/00-setup-01.png)

1. GitHub Codespaces 인스턴스 안에서 아래 명령어를 실행시켜 애저 및 GitHub에 로그인합니다.

   ```bash
   # Azure Developer CLI login
   azd auth login --use-device-code=false

   # Azure CLI login
   az login

   # GitHub CLI login
   GITHUB_TOKEN=
   gh auth login
   ```

   > **중요**: 만약 `azd auth login --use-device-code false` 또는 `az login` 명령어 실행시 새 브라우저 탭이 뜨면서 404 에러가 날 경우, 주소창의 URL 값을 복사해서 새 zsh 터미널을 열고 `curl <복사한 URL>`을 해 줍니다.

1. 로그인이 끝났다면 아래 명령어를 통해 제대로 로그인이 되어 있는지 확인합니다.

   ```bash
   # Azure Developer CLI
   azd auth login --check-status

   # Azure CLI
   az account show

   # GitHub CLI
   gh auth status
   ```

---

축하합니다! 개발 환경 설정이 끝났습니다. 이제 [Session 01: Blazor 프론트엔드 웹 앱 개발](./01-blazor-frontend.md)로 넘어가세요.
