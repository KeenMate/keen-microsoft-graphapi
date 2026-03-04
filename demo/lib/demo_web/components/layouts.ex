defmodule DemoWeb.Layouts do
  use Phoenix.Component

  def root(assigns) do
    ~H"""
    <!DOCTYPE html>
    <html lang="en">
      <head>
        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <meta name="csrf-token" content={Phoenix.Controller.get_csrf_token()} />
        <title>Graph Explorer — MicrosoftGraph Elixir</title>
        <style>
          * { margin: 0; padding: 0; box-sizing: border-box; }

          body {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
            font-size: 14px;
            color: #1a1a1a;
            background: #f5f5f5;
          }

          .explorer-grid {
            display: grid;
            grid-template-columns: 20% 30% 50%;
            height: 100vh;
          }

          /* Left column — endpoint navigator */
          .nav-column {
            background: #fafafa;
            border-right: 1px solid #e0e0e0;
            overflow-y: auto;
            padding: 0;
          }

          .nav-header {
            padding: 16px;
            font-size: 16px;
            font-weight: 600;
            color: #333;
            border-bottom: 1px solid #e0e0e0;
            background: #fff;
            position: sticky;
            top: 0;
            z-index: 1;
          }

          .nav-group-label {
            padding: 10px 16px 4px;
            font-size: 11px;
            font-weight: 700;
            text-transform: uppercase;
            letter-spacing: 0.5px;
            color: #888;
          }

          .nav-item {
            display: flex;
            align-items: center;
            gap: 8px;
            padding: 6px 16px;
            cursor: pointer;
            border-left: 3px solid transparent;
            transition: background 0.1s;
          }

          .nav-item:hover { background: #eef2f7; }

          .nav-item.active {
            background: #e8f0fe;
            border-left-color: #0078d4;
          }

          .method-badge {
            display: inline-block;
            font-size: 10px;
            font-weight: 700;
            padding: 1px 5px;
            border-radius: 3px;
            text-transform: uppercase;
            min-width: 40px;
            text-align: center;
            font-family: "SF Mono", Monaco, "Cascadia Code", monospace;
          }

          .method-get    { background: #e6f4ea; color: #1e7e34; }
          .method-post   { background: #fff3e0; color: #e65100; }
          .method-patch  { background: #f3e5f5; color: #7b1fa2; }
          .method-delete { background: #fce4ec; color: #c62828; }

          .nav-item-label {
            font-size: 13px;
            color: #333;
          }

          /* Middle column — parameter builder */
          .param-column {
            background: #fff;
            border-right: 1px solid #e0e0e0;
            overflow-y: auto;
            padding: 0;
          }

          .param-header {
            padding: 16px;
            font-size: 16px;
            font-weight: 600;
            color: #333;
            border-bottom: 1px solid #e0e0e0;
            background: #fff;
            position: sticky;
            top: 0;
            z-index: 1;
          }

          .param-section {
            padding: 12px 16px;
            border-bottom: 1px solid #f0f0f0;
          }

          .param-description {
            font-size: 13px;
            color: #555;
            line-height: 1.4;
          }

          .param-section-title {
            font-size: 11px;
            font-weight: 700;
            text-transform: uppercase;
            letter-spacing: 0.5px;
            color: #888;
            margin-bottom: 8px;
          }

          .param-field {
            margin-bottom: 8px;
          }

          .param-field label {
            display: block;
            font-size: 12px;
            font-weight: 500;
            color: #555;
            margin-bottom: 3px;
          }

          .param-field input,
          .param-field textarea,
          .param-field select {
            width: 100%;
            padding: 6px 8px;
            border: 1px solid #d0d0d0;
            border-radius: 4px;
            font-size: 13px;
            font-family: inherit;
          }

          .param-field input:focus,
          .param-field textarea:focus,
          .param-field select:focus {
            outline: none;
            border-color: #0078d4;
            box-shadow: 0 0 0 2px rgba(0, 120, 212, 0.15);
          }

          .param-field textarea {
            font-family: "SF Mono", Monaco, "Cascadia Code", monospace;
            font-size: 12px;
            min-height: 120px;
            resize: vertical;
          }

          .toggle-row {
            display: flex;
            align-items: center;
            gap: 16px;
            flex-wrap: wrap;
          }

          .toggle-item {
            display: flex;
            align-items: center;
            gap: 6px;
            font-size: 13px;
          }

          .toggle-item select {
            width: auto;
            padding: 4px 8px;
            font-size: 13px;
          }

          .toggle-item input[type="checkbox"] {
            width: auto;
          }

          .param-hint {
            margin-top: 6px;
            font-size: 11px;
            color: #888;
            line-height: 1.4;
          }

          .param-hint code {
            background: #f0f0f0;
            padding: 1px 4px;
            border-radius: 3px;
            font-family: "SF Mono", Monaco, "Cascadia Code", monospace;
            font-size: 10px;
          }

          .execute-btn {
            display: block;
            width: 100%;
            padding: 10px;
            margin-top: 4px;
            background: #0078d4;
            color: #fff;
            border: none;
            border-radius: 6px;
            font-size: 14px;
            font-weight: 600;
            cursor: pointer;
            transition: background 0.15s;
          }

          .execute-btn:hover { background: #106ebe; }
          .execute-btn:disabled { background: #a0c4e8; cursor: not-allowed; }

          .empty-state {
            padding: 32px 16px;
            text-align: center;
            color: #999;
            font-size: 13px;
          }

          /* Right column — results */
          .result-column {
            background: #fff;
            overflow-y: auto;
            padding: 0;
            display: flex;
            flex-direction: column;
          }

          .result-header {
            padding: 12px 16px;
            border-bottom: 1px solid #e0e0e0;
            background: #fff;
            position: sticky;
            top: 0;
            z-index: 1;
            display: flex;
            align-items: center;
            gap: 16px;
          }

          .result-header-title {
            font-size: 16px;
            font-weight: 600;
            color: #333;
          }

          .tab-bar {
            display: flex;
            gap: 0;
          }

          .tab-btn {
            padding: 6px 14px;
            font-size: 13px;
            font-weight: 500;
            background: #f0f0f0;
            border: 1px solid #d0d0d0;
            cursor: pointer;
            color: #555;
          }

          .tab-btn:first-child { border-radius: 4px 0 0 4px; }
          .tab-btn:last-child { border-radius: 0 4px 4px 0; border-left: none; }

          .tab-btn.active {
            background: #0078d4;
            color: #fff;
            border-color: #0078d4;
          }

          .metadata-banner {
            padding: 8px 16px;
            background: #e8f4fd;
            border-bottom: 1px solid #b3d7f2;
            font-size: 12px;
            color: #0c5a97;
            display: flex;
            gap: 16px;
            flex-wrap: wrap;
          }

          .metadata-item {
            display: flex;
            gap: 4px;
          }

          .metadata-label {
            font-weight: 600;
          }

          .metadata-value {
            font-family: "SF Mono", Monaco, "Cascadia Code", monospace;
            word-break: break-all;
          }

          .next-page-btn {
            padding: 4px 12px;
            font-size: 12px;
            font-weight: 600;
            background: #0078d4;
            color: #fff;
            border: none;
            border-radius: 4px;
            cursor: pointer;
            white-space: nowrap;
          }

          .next-page-btn:hover { background: #106ebe; }

          .result-body {
            flex: 1;
            overflow-y: auto;
            padding: 16px;
          }

          .json-output {
            background: #1e1e1e;
            color: #d4d4d4;
            padding: 16px;
            border-radius: 6px;
            font-family: "SF Mono", Monaco, "Cascadia Code", monospace;
            font-size: 12px;
            line-height: 1.5;
            white-space: pre-wrap;
            word-break: break-all;
            overflow-x: auto;
          }

          .error-box {
            padding: 12px 16px;
            background: #fef2f2;
            border: 1px solid #fca5a5;
            border-radius: 6px;
            color: #991b1b;
            font-size: 13px;
          }

          .error-box-title {
            font-weight: 700;
            margin-bottom: 4px;
          }

          .error-box pre {
            margin-top: 8px;
            font-family: "SF Mono", Monaco, "Cascadia Code", monospace;
            font-size: 12px;
            white-space: pre-wrap;
            word-break: break-all;
          }

          .loading-spinner {
            display: flex;
            align-items: center;
            gap: 8px;
            padding: 32px 16px;
            color: #0078d4;
            font-size: 14px;
          }

          .spinner {
            width: 20px;
            height: 20px;
            border: 2px solid #b3d7f2;
            border-top-color: #0078d4;
            border-radius: 50%;
            animation: spin 0.8s linear infinite;
          }

          @keyframes spin {
            to { transform: rotate(360deg); }
          }

          /* Visual result cards */
          .result-cards {
            display: flex;
            flex-direction: column;
            gap: 8px;
          }

          .result-card {
            border: 1px solid #e0e0e0;
            border-radius: 6px;
            padding: 12px;
            background: #fafafa;
          }

          .result-card-title {
            font-weight: 600;
            font-size: 14px;
            margin-bottom: 6px;
            color: #1a1a1a;
          }

          .result-card-fields {
            display: grid;
            grid-template-columns: auto 1fr;
            gap: 2px 12px;
            font-size: 12px;
          }

          .result-card-key {
            color: #888;
            font-weight: 500;
          }

          .result-card-value {
            color: #333;
            word-break: break-all;
          }

          .result-count {
            font-size: 12px;
            color: #888;
            margin-bottom: 8px;
          }

          .result-table {
            width: 100%;
            border-collapse: collapse;
            font-size: 12px;
          }

          .result-table th {
            text-align: left;
            padding: 6px 8px;
            background: #f5f5f5;
            border-bottom: 2px solid #e0e0e0;
            font-weight: 600;
            color: #555;
          }

          .result-table td {
            padding: 6px 8px;
            border-bottom: 1px solid #f0f0f0;
            word-break: break-all;
            max-width: 300px;
          }

          .result-table tr:hover td {
            background: #f9f9f9;
          }
        </style>
        <script defer phx-track-static src="/assets/phoenix/phoenix.min.js">
        </script>
        <script defer phx-track-static src="/assets/phoenix_live_view/phoenix_live_view.min.js">
        </script>
        <script>
          window.addEventListener("DOMContentLoaded", () => {
            let liveSocket = new window.LiveView.LiveSocket("/live", window.Phoenix.Socket);
            liveSocket.connect();
          });
        </script>
      </head>
      <body>
        {@inner_content}
      </body>
    </html>
    """
  end
end
