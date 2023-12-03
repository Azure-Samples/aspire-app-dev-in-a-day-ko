# 세션 05: Blazor JavaScript Interoperability 적용

이 세션에서는 [Blazor 프론트엔드 웹 앱](https://learn.microsoft.com/ko-kr/aspnet/core/blazor?WT.mc_id=dotnet-113934-juyoo)의 [JS Interop 기능](https://learn.microsoft.com/ko-kr/aspnet/core/blazor/javascript-interoperability/?WT.mc_id=dotnet-113934-juyoo)을 활용해 React 기반의 UI 컴포넌트를 통합해 보겠습니다.

> [GitHub Codespaces](https://docs.github.com/ko/codespaces/overview) 환경에서 작업하는 것을 기준으로 진행합니다. 로컬 개발 환경의 [Visual Studio Code](https://code.visualstudio.com/?WT.mc_id=dotnet-113934-juyoo)를 사용할 경우 대부분 비슷하지만 살짝 다를 수 있습니다.

## 05-1: React 기반 UI 컴포넌트 생성하기 - Fluid UI Progress Indicator

1. 아래 명령어를 차례로 실행시켜 Aspire 프로젝트를 복원합니다.

    ```bash
    cd $CODESPACE_VSCODE_FOLDER
    mkdir -p workshop && cp -a save-points/session-04/. workshop/
    cd workshop
    dotnet restore && dotnet build
    ```

1. `AspireYouTubeSummariser.WebApp` 프로젝트에 `JSInterop` 디렉토리를 생성합니다.

    ```bash
    cd $CODESPACE_VSCODE_FOLDER/workshop/AspireYouTubeSummariser.WebApp
    mkdir JSInterop
    cd JSInterop
    ```

1. 아래 명령어를 실행시켜 node.js 기반의 React 프로젝트를 생성합니다.

    ```bash
    npm init
    ```

   초기화 과정에서 물어보는 아래의 질문에는 엔터키를 눌러 기본값으로 설정하고 지나갑니다.

    ```text
    package name:
    version:
    description:
    entry point:
    test command:
    git repository:
    keywords:
    author:
    license:
    ```

1. 생성된 `package.json` 파일을 열고 아래 내용으로 수정합니다.

    ```json
    {
      "scripts": {
        // 수정 전
        "test": "echo \"Error: no test specified\" && exit 1"
    
        // 수정 후
        "build": "webpack --mode production"
      },
    }
    ```

1. 아래 명령어를 차례로 실행시켜 npm 패키지를 설치합니다.

    ```bash
    npm install --save-dev @babel/core babel-loader webpack webpack-cli
    npm install @fluentui/react react react-dom
    ```

1. `webpack.config.js` 파일을 생성한 후 아래 내용을 입력합니다.

    ```nodejs
    const path = require("path");
    
    module.exports = {
      module: {
        rules: [
          {
            test: /\.js$/,
            exclude: /node_modules/,
            use: {
              loader: "babel-loader"
            }
          }
        ]
      },
      output: {
        path: path.resolve(__dirname, '../wwwroot/js'),
        filename: "bundle.js",
        library: "YouTube",
        libraryTarget: "window"
      }
    };
    ```

1. `src` 디렉토리를 만들고 그 아래 `index.js` 파일을 생성한 후 아래와 같이 입력합니다.

    ```nodejs
    import { renderProgressBar } from './progressbar';
    
    export function RenderProgressBar() {
      return renderProgressBar();
    }
    ```

1. `src` 디렉토리 밑에 `progressbar.js` 파일을 생성한 후 아래와 같이 입력합니다.

    ```nodejs
    import * as React from 'react';
    import ReactDOM from 'react-dom';
    import { ProgressIndicator } from '@fluentui/react/lib/ProgressIndicator';
    
    export function renderProgressBar(count) {
        const Progress = () => React.createElement(
            ProgressIndicator,
            {
                'label': 'Summarising...',
                'description': ''
            },
            null
        );
    
        ReactDOM.render(Progress(), document.getElementById('progressBar'));
    }
    ```

## 05-2: Blazor 프론트엔드 웹 앱에 React 기반 UI 컴포넌트 통합하기

1. `AspireYouTubeSummariser.WebApp` 프로젝트의 `AspireYouTubeSummariser.WebApp.csproj` 파일을 열어 프로젝트를 빌드할 때 앞서 작성했던 React UI 컴포넌트 역시 동시에 빌드될 수 있게 설정합니다.

    ```xml
    <Project Sdk="Microsoft.NET.Sdk.Web">
    
      <PropertyGroup>
        <!-- 추가 -->
        <JSInteropRoot>JSInterop/</JSInteropRoot>
        <DefaultItemExcludes>$(DefaultItemExcludes);$(JSInteropRoot)node_modules/**</DefaultItemExcludes>
      </PropertyGroup>
    
      <!-- 추가 -->
      <ItemGroup>
        <Content Remove="$(JSInteropRoot)**" />
        <None Remove="$(JSInteropRoot)**" />
        <None Include="$(JSInteropRoot)**" Exclude="$(JSInteropRoot)node_modules/**" />
      </ItemGroup>
    
      ...
    
      <!-- 추가 -->
      <Target Name="PublishRunWebpack" AfterTargets="Build">
        <!-- As part of publishing, ensure the JS resources are freshly built in production mode -->
        <Exec WorkingDirectory="$(JSInteropRoot)" Command="npm install" />
        <Exec WorkingDirectory="$(JSInteropRoot)" Command="npm run build" />
      </Target>
    
    </Project>
    ```

1. `AspireYouTubeSummariser.WebApp` 프로젝트의 `Components/UI` 디렉토리에 있는 `YouTubeSummariserComponent.razor` 파일을 열고 `@inject IApiAppClient ApiApp` 라인 아래 아래와 같이 수정합니다.

    ```razor
    @inject IApiAppClient ApiApp
    
    @* 추가 *@
    @inject IJSRuntime JSR
    ```

1. 같은 파일에서 HTML 버튼 아래 아래와 같이 HTML 엘리먼트를 추가합니다.

    ```razor
    <div class="row">
        <div class="mb-3">
            <button type="button" class="btn btn-primary" @onclick="SummariseAsync">Summarise!</button>
            <button type="button" class="btn btn-secondary" @onclick="ClearAsync">Clear!</button>
        </div>
    </div>
    
    @* 추가 *@
    <div class="row">
        <div class="mb-3">
            <div id="progressBar" hidden="@summaryCompleted"></div>
        </div>
    </div>
    ```

1. 같은 파일에서 `@code` 블록을 아래와 같이 수정합니다.

    ```razor
    @code {
        ...
        
        private string summaryResult = string.Empty;
        
        // 추가
        private bool summaryCompleted;
        
        private async Task SummariseAsync()
        {
            // 추가
            summaryCompleted = false;
            await JSR.InvokeVoidAsync("YouTube.RenderProgressBar");
    
            var result = await ApiApp.SummariseAsync(youTubeLinkUrl, videoLanguageCode, summaryLanguageCode);
            summaryResult = result;
        
            // 추가
            summaryCompleted = true;
        }
    
        ...
    }    
    ```

1. `AspireYouTubeSummariser.WebApp` 프로젝트의 `Components` 디렉토리에 있는 `App.razor` 파일을 열고 `<script src="_framework/blazor.web.js"></script>` 라인을 찾아 아래와 같이 수정합니다.

```html
<script src="_framework/blazor.web.js"></script>

<!-- 추가 -->
<script src="js/bundle.js"></script>
```

## 05-3: Aspire 프로젝트 빌드 및 실행하기

1. `AspireYouTubeSummariser.WebApp` 프로젝트의 `Program.cs` 파일을 열고 아래 내용으로 수정합니다.

    ```csharp
    // 수정 전
    builder.Services.AddHttpClient<IApiAppClient, ApiAppClient>(p => p.BaseAddress = new Uri("https://apiapp"));
    
    //수정 후
    builder.Services.AddHttpClient<IApiAppClient, ApiAppClient>(p => p.BaseAddress = new Uri("http://apiapp"));
    ```

    > 위 수정 사항은 GitHub Codespaces 환경에서만 필요합니다. 로컬 개발 환경에서는 항상 `https://apiapp`으로 설정해두면 됩니다.

1. Solution Explorer에서 `AspireYouTubeSummariser.AppHost` 프로젝트를 선택하고 마우스 오른쪽 버튼을 눌러 디버깅 모드로 실행합니다.
1. 대시보드 페이지를 열고 Blazor 프론트엔드 웹 앱을 실행시킵니다.
1. 홈페이지에서 YouTube 링크를 입력하고 `Summarise` 버튼을 클릭합니다.
1. `Summarising...`이라는 텍스트와 함께 진행 상태바가 움직이는 것을 확인합니다.

## 05-4: Aspire 프로젝트 배포하기

1. `AspireYouTubeSummariser.WebApp` 프로젝트의 `Program.cs` 파일을 열고 아래 내용으로 수정합니다.

    ```csharp
    // 수정 전
    builder.Services.AddHttpClient<IApiAppClient, ApiAppClient>(p => p.BaseAddress = new Uri("http://apiapp"));
    
    //수정 후
    builder.Services.AddHttpClient<IApiAppClient, ApiAppClient>(p => p.BaseAddress = new Uri("https://apiapp"));
    ```

    > 위 수정 사항은 GitHub Codespaces 환경에서만 필요합니다. 로컬 개발 환경에서는 항상 `https://apiapp`으로 설정해두면 됩니다.

1. 아래 명령어를 실행시켜 앱을 배포합니다.

    ```bash
    azd deploy
    ```

1. 배포가 끝난 후 `webapp` 컨테이너 앱을 실행시켜 홈페이지에서 YouTube 링크를 입력하고 `Summarise` 버튼을 클릭합니다.
1. `Summarising...`이라는 텍스트와 함께 진행 상태바가 움직이는 것을 확인합니다.

---

축하합니다! Blazor 프론트엔드 웹 앱에 JS Interop 기능을 통해 React 기반의 UI 컴포넌트를 통합하는 작업이 끝났습니다.
