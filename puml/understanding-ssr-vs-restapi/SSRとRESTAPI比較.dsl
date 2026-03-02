workspace "SSRとRESTAPI比較" "Container図およびComponent図で比較する" {
	model {
		user = person "ユーザー" "ブラウザからアクセス"

		// -----------------------------------
		// SpringMVC + Thymeleaf + SpringJDBC 
		// -----------------------------------
		mvcSystem = softwareSystem "MVCシステム" "描画処理とロジックが一体化" {
			mvcApplication = container "WEBアプリケーション" "HTML生成+ビジネスロジック実行" "SpringBoot: MVC/JDBC" {
				mvcController = component "MVC Controller" "HTTPリクエストを受付+View名を返却" "Spring: @Controller"
				mvcService    = component "Service" "ビジネスロジックを実行する" "Spring: @Service"
				mvcRepository = component "Repository" "データベースと通信する" "Spring: @Repository"
			}

			mvcDatabase = container "データベース" "データを保存" "RDBMS"
		}

		user -> mvcController "画面操作/HTTPリクエスト" "HTTP/HTML"
		mvcController -> mvcService "処理を移譲"
		mvcService -> mvcRepository "データ操作を依頼"
		mvcRepository -> mvcDatabase "JDBC/SQL"

		// -----------------------------------
		//             REST API               
		// -----------------------------------
		restSystem = softwareSystem "REST APIシステム" "フロントエンドとバックエンドが分離" {
			frontend = container "フロントエンド" "画面描画+ユーザー操作受付" "Reactなど"

			restapiApplication = container "バックエンドAPI" "JSONデータの提供+ビジネスロジック実行" "SpringBoot: REST" {
				restController = component "RestController" "HTTPリクエストを受付+JSONデータを返却する" "Spring: @RestController"
				restService    = component "Service" "ビジネスロジックを実行する" "Spring: @Service"
				restRepository = component "Repository" "データベースと通信する" "Spring: @Repository"
			}

			restapiDatabase = container "データベース" "データを保存" "RDBMS"
		}

		user -> frontend "画面操作"
		frontend -> restController "API呼び出し" "HTTP/JSON"
		restController -> restService "処理を移譲"
		restService -> restRepository "データ操作を依頼"
		restRepository -> restapiDatabase "JDBC/SQL"
	}

	views {
		// -----------------------------------
		//          ContainerDiagram          
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
		//          ComponentDiagram          
		// -----------------------------------
		component mvcApplication "SSR-ComponentDiagram" {
			include *
			autoLayout lr
			description "SSR内部:@ControllerがView名を返す"
		}

		component restapiApplication "RESTAPI-ComponentDiagram" {
			include *
			autoLayout lr
			description "REST内部:@RestControllerがJSONデータを返す"
		}
	}
}
