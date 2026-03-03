workspace "SSRとRESTAPI比較" "Container図およびComponent図で比較する" {
	model {
		user = person "ユーザー" "ブラウザを通じてシステムを利用"

		// -----------------------------------
		// 1. SSR(ServerSideRendering)        
		// -----------------------------------
		mvcSystem = softwareSystem "WEBシステム(SSR構成)" "HTML描画とロジックをサーバー側で一括管理" {
			mvcApplication = container "WEBアプリケーション" "ビジネスロジック実行とHTML画面の提供" "SpringBoot(SpringMVC)" {
				mvcController = component "MVCController" "HTTPリクエスト受付とView名返却" "Spring: @Controller"
				mvcService    = component "Service" "ビジネスロジックの実行とDTO返却" "Spring: @Service"
				mvcRepository = component "Repository" "SQLの実行とEntity返却" "Spring: @Repository"
			}

			mvcDatabase = container "データベース" "データの永続化" "RDBMS"
		}

		user          -> mvcController "画面操作/HTTPリクエスト" "HTTP/HTML"
		mvcController -> mvcService    "処理を移譲"
		mvcService    -> mvcRepository "データベース操作を依頼"
		mvcRepository -> mvcDatabase   "JDBC/SQL"

		// -----------------------------------
		// 2. RESTAPI(Decoupled Architecture)
		// -----------------------------------
		restSystem = softwareSystem "WEBシステム(分離構成)" "フロントエンドとバックエンドを役割で分離" {
			group "クライアント(ブラウザ)" {
				frontend = container "フロントエンド" "ユーザー操作の制御と画面の構築" "Reactなど"
			}

			group "WEBサーバー" {
				restapiApplication = container "バックエンド" "ビジネスロジックの実行とJSONデータ提供" "SpringBoot(RESTAPI)" {
					restController = component "RestController" "HTTPリクエスト受付とJSONデータ返却" "Spring: @RestController"
					restService    = component "Service" "ビジネスロジックの実行とDTO返却" "Spring: @Service"
					restRepository = component "Repository" "SQLの実行とEntity返却" "Spring: @Repository"
				}
			}

			restapiDatabase = container "データベース" "データの永続化" "RDBMS"
		}

		user           -> frontend        "画面操作"
		frontend       -> restController  "API呼び出し" "HTTP/JSON"
		restController -> restService     "処理を移譲"
		restService    -> restRepository  "データベース操作を依頼"
		restRepository -> restapiDatabase "JDBC/SQL"
	}

	views {
		// -----------------------------------
		// 1. ContainerDiagram                
		// -----------------------------------
		container mvcSystem "SSR-ContainerDiagram" {
			include *
			autoLayout lr
			description "SSR:画面とバックエンドが一体化"
		}

		container restSystem "RESTAPI-ContainerDiagram" {
			include *
			autoLayout lr
			description "RESTAPI:フロントエンドとバックエンドが分離"
		}

		// -----------------------------------
		// 2. ComponentDiagram                
		// -----------------------------------
		component mvcApplication "SSR-ComponentDiagram" {
			include *
			autoLayout lr
			description "SSR内部:@ControllerがView名を提供する"
		}

		component restapiApplication "RESTAPI-ComponentDiagram" {
			include *
			autoLayout lr
			description "REST内部:@RestControllerがJSONデータを提供する"
		}
	}
}
