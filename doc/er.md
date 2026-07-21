# ER図

basil-managerで管理する業務テーブルの関連を示します。
各テーブルのカラム、制約、業務ルールの詳細は、`db` 配下の仕様書を
参照してください。

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
    STOCK ||--o{ STOCK_OBSERVATION : has
    LOCATION ||--o{ LOCATION_OBSERVATION : has

    PLANT {
        int id PK
        string code UK
        string prefix UK
        string name UK
        int last_stock_number
    }

    STOCK {
        int id PK
        int plant_id FK
        int location_id FK
        int parent_stock_id FK
        string public_token UK
        string code UK
        string status
        string growing_method
        string propagation_method
        string completion_reason
        datetime completed_at
    }

    LOCATION {
        int id PK
        string code UK
        string prefix UK
        string name UK
    }

    STOCK_ACTION_LOG {
        int id PK
        int stock_id FK
        string action_type
        text memo
        datetime recorded_at
    }

    STOCK_OBSERVATION {
        int id PK
        int stock_id FK
        decimal height_cm
        text memo
        datetime recorded_at
    }

    LOCATION_OBSERVATION {
        int id PK
        int location_id FK
        decimal temperature
        string weather
        text memo
        datetime recorded_at
    }
```
