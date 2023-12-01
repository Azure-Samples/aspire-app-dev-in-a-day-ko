# 세션 01: Blazor 프론트엔드 웹 앱 개발

이 세션에서는 [GitHub Copilot](https://docs.github.com/ko/copilot/overview-of-github-copilot/about-github-copilot-business) 기능을 활용해 빠르게 [Blazor 프론트엔드 웹 앱](https://learn.microsoft.com/ko-kr/aspnet/core/blazor?WT.mc_id=dotnet-113934-juyoo) 개발을 해 보겠습니다.

> [GitHub Codespaces](https://docs.github.com/ko/codespaces/overview) 환경에서 작업하는 것을 기준으로 진행합니다. 로컬 개발 환경의 [Visual Studio Code](https://code.visualstudio.com/?WT.mc_id=dotnet-113934-juyoo)를 사용할 경우 대부분 비슷하지만 살짝 다를 수 있습니다.

## 01-1: Blazor 프로젝트 생성하기

1. 터미널을 열고 아래 명령어를 차례로 실행시켜 실습 디렉토리를 만들고 이동합니다.

   ```bash
   mkdir workshop
   cd workshop
   ```

1. 아래 명령어를 차례로 실행시켜 Blazor 웹 앱 프로젝트를 생성합니다.

   ```bash
   dotnet new sln -n AspireYouTubeSummariser
   dotnet new blazor -n AspireYouTubeSummariser.WebApp -int server -ai true
   dotnet sln add AspireYouTubeSummariser.WebApp
   ```

1. 아래 명령어를 차례로 실행시켜 Blazor 웹 앱 프로젝트를 빌드하고 실행시킵니다.

   ```bash
   dotnet restore && dotnet build
   dotnet run --project AspireYouTubeSummariser.WebApp
   ```

## 01-2: UI Component 생성하기

