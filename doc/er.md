# ER図

basil-managerで管理する業務テーブルの関連を示します。
各テーブルのカラム、制約、業務ルールの詳細は、`db` 配下の仕様書を
参照してください。

画像はActive Storageの内部テーブルで管理するため、この業務テーブルの
ER図には含めません。`Plant`、`Location`、`StockObservation`が
それぞれ1枚の画像を添付できます。

各履歴の`recorded_at`はNULLを許可します。記録だけを先に作成し、
実際の記録日時を後から入力する運用があるためです。

- [`plants` テーブル](db/plant.md)
- [`stocks` テーブル](db/stock.md)
- [`locations` テーブル](db/location.md)
- [`stock_action_logs` テーブル](db/stock_action_log.md)
- [`stock_observations` テーブル](db/stock_observation.md)
- [`location_observations` テーブル](db/location_observation.md)

```mermaid
erDiagram
    PLANT ||--o{ STOCK : has
    LOCATION ||--o{ STOCK : stores
    STOCK o|--o{ STOCK : parent_of
    STOCK ||--o{ STOCK_ACTION_LOG : has
    LOCATION o|--o{ STOCK_ACTION_LOG : from
    LOCATION o|--o{ STOCK_ACTION_LOG : to
    STOCK ||--o{ STOCK_OBSERVATION : has
    LOCATION ||--o{ LOCATION_OBSERVATION : has

    PLANT {
        bigint id PK
        string code UK
        string prefix UK
        string name UK
        integer last_stock_number
        string scientific_name "NULL可"
        text temperature_requirements "NULL可"
        text climate_requirements "NULL可"
        text growing_season "NULL可"
        text sunlight_requirements "NULL可"
        text watering_guide "NULL可"
        text fertilizing_guide "NULL可"
        text ventilation_requirements "NULL可"
        text soil_requirements "NULL可"
        text pruning_guide "NULL可"
        text overwintering_guide "NULL可"
        text care_notes "NULL可"
        text care_cautions "NULL可"
    }

    STOCK {
        bigint id PK
        bigint plant_id FK
        bigint location_id FK
        bigint parent_stock_id FK "NULL可"
        boolean parent_stock_candidate
        string public_token UK
        string code UK
        string status
        string growing_method
        string propagation_method "NULL可"
        integer quantity
        text memo "NULL可"
        string completion_reason "NULL可"
        datetime completed_at "NULL可"
    }

    LOCATION {
        bigint id PK
        string code UK
        string prefix UK
        string name UK
        string environment
    }

    STOCK_ACTION_LOG {
        bigint id PK
        bigint stock_id FK
        string action_type
        bigint from_location_id FK "NULL可"
        bigint to_location_id FK "NULL可"
        integer quantity_before "NULL可"
        integer quantity_after "NULL可"
        string status_before "NULL可"
        string status_after "NULL可"
        text memo "NULL可"
        datetime recorded_at "NULL可"
    }

    STOCK_OBSERVATION {
        bigint id PK
        bigint stock_id FK
        decimal height_cm "NULL可"
        text memo "NULL可"
        datetime recorded_at "NULL可"
    }

    LOCATION_OBSERVATION {
        bigint id PK
        bigint location_id FK
        decimal temperature "NULL可"
        string weather "NULL可"
        text memo "NULL可"
        datetime recorded_at "NULL可"
    }
```
