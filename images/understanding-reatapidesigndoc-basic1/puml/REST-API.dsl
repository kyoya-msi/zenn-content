workspace "RESTAPI構成図" "" {
	model {
		// -----------------------------------
		//         コンポーネント定義           
		// -----------------------------------
		user = person "ユーザー" "ブラウザを通じてシステムを利用"

		websystem = softwareSystem "WEBシステム" "WEBサービス全体" {
			group "クライアント(ブラウザ)" {
				frontend = container "フロントエンド" "ユーザー操作の制御と画面の構築" "Reactなど"
			}

			group "WEBサーバー" {
				backend = container "バックエンド" "ビジネスロジックの実行とJSONデータ提供" "SpringBoot" {
					controller = component "Controller" "HTTPリクエスト受付とJSONデータ返却" "Spring: @RestController"
					service    = component "Service" "ビジネスロジックの実行とDTO返却" "Spring: @Service"
					repository = component "Repository" "SQLの実行とEntity返却" "Spring: @Repository"
				}

				database = container "データベース" "データの永続化" "RDBMS"
			}
		}

		// -----------------------------------
		//            依存関係定義             
		// -----------------------------------
		user       -> frontend   "画面操作"
		frontend   -> controller "API呼び出し"           "HTTP/JSON"
		controller -> service    "処理を移譲"
		service    -> repository "データベース操作を依頼"
		repository -> database   "JDBC/SQL"
	}

	views {
		// -----------------------------------
		// 1. ContextDiagram                  
		// -----------------------------------
		systemContext websystem "ContextDiagram" {
			include *
			autoLayout lr
		}

		// -----------------------------------
		// 2. ContainerDiagram                
		// -----------------------------------
		container websystem "ContainerDiagram" {
			include *
			autoLayout lr
		}

		// -----------------------------------
		// 3. ComponentDiagram                
		// -----------------------------------
		component backend "ComponentDiagram" {
			include *
			autoLayout lr
		}

		theme default
	}
}
