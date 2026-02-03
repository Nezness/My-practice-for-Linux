```mermaid

graph TB
    subgraph "クライアント層"
        iOS[iOSアプリ]
    end

    subgraph "認証層"
        Cognito[Amazon Cognito<br/>ユーザープール]
    end

    subgraph "APIレイヤー"
        APIGW[API Gateway<br/>REST API]
    end

    subgraph "処理層 - アップロード"
        Lambda1[Lambda関数①<br/>署名付きURL発行]
    end

    subgraph "ストレージ層"
        S3[Amazon S3<br/>レシート画像保存]
    end

    subgraph "処理層 - OCR"
        Lambda2[Lambda関数②<br/>Textract呼び出し]
        Textract[Amazon Textract<br/>OCR処理]
    end

    subgraph "処理層 - データ保存"
        Lambda3[Lambda関数③<br/>データ整形・保存]
    end

    subgraph "データベース層"
        DynamoDB[Amazon DynamoDB<br/>レシートデータ保存]
    end

    subgraph "処理層 - AI分析"
        Lambda4[Lambda関数④<br/>分析リクエスト]
        KB[Knowledge Bases<br/>for Amazon Bedrock]
        Bedrock[Amazon Bedrock<br/>Claude 4.5 Sonnet]
    end

    %% フロー定義
    iOS -->|①ログイン| Cognito
    Cognito -->|認証トークン| iOS
    iOS -->|②署名付きURL要求| APIGW
    APIGW -->|③呼び出し| Lambda1
    Lambda1 -->|④署名付きURL生成| S3
    Lambda1 -->|⑤署名付きURL返却| APIGW
    APIGW -->|⑥署名付きURL返却| iOS
    iOS -->|⑦画像アップロード| S3
    
    S3 -->|⑧S3イベント通知| Lambda2
    Lambda2 -->|⑨OCR依頼| Textract
    Textract -->|⑩抽出データ返却| Lambda2
    Lambda2 -->|⑪データ送信| Lambda3
    Lambda3 -->|⑫データ保存| DynamoDB
    
    iOS -->|⑬分析リクエスト| APIGW
    APIGW -->|⑭呼び出し| Lambda4
    Lambda4 -->|⑮データ取得| DynamoDB
    Lambda4 -->|⑯RAG検索| KB
    KB -->|⑰関連データ| Lambda4
    Lambda4 -->|⑱分析依頼| Bedrock
    Bedrock -->|⑲アドバイス生成| Lambda4
    Lambda4 -->|⑳結果返却| APIGW
    APIGW -->|㉑結果返却| iOS

    %% スタイリング
    classDef client fill:#e1f5ff,stroke:#01579b,stroke-width:3px, color:#000000, font-size:24px;
    classDef auth fill:#fff3e0,stroke:#e65100,stroke-width:3px, color:#000000, font-size:24px;
    classDef api fill:#f3e5f5,stroke:#4a148c,stroke-width:3px, color:#000000, font-size:24px;
    classDef compute fill:#e8f5e9,stroke:#1b5e20,stroke-width:3px, color:#000000, font-size:24px;
    classDef storage fill:#fff9c4,stroke:#f57f17,stroke-width:3px, color:#000000, font-size:24px;
    classDef ai fill:#fce4ec,stroke:#880e4f,stroke-width:3px, color:#000000, font-size:24px;
    classDef db fill:#e0f2f1,stroke:#004d40,stroke-width:3px, color:#000000, font-size:24px;
    

    class iOS client
    class Cognito auth
    class APIGW api
    class Lambda1,Lambda2,Lambda3,Lambda4 compute
    class S3 storage
    class Textract ai
    class DynamoDB db
    class Bedrock,KB ai
    ```