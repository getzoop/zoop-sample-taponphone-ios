# Processo de Criação de Novos Repositórios

## 1. Rodar a Action
- Rodar a action em [Zoop Template Actions](https://github.com/getzoop/zoop-template/actions).
- O nome não precisa conter 'zoop', pois a action já ajusta automaticamente.

## 2. Ajustar o Repositório Criado
- Ajustar o arquivo `CODEOWNERS`, colocando o nome do grupo de quem solicitou em primeiro lugar.
- Limpar o conteúdo do arquivo `README.md`.

## 3. Ajustar a Action `run_security_check`
- Alterar a linguagem do projeto no arquivo `.github/workflows`.
  - Essa informação deve ser fornecida pelo solicitante.
  - Caso a linguagem seja Go, incluir o campo `go-version` abaixo de `language`. Essa informação também deve ser fornecida pelo solicitante.

## 4. Incluir o Projeto no SonarCloud - se for repo só de terraform pular essa etapada
- Acessar [SonarCloud](https://sonarcloud.io/).
- Clicar no sinal de '+' ao lado do usuário e selecionar "Analyze new project".
- Ajustar o arquivo `sonar-project.properties`, ele está na raiz do novo projeto criado pela action do git.

## 5. Aplicar Bloqueios de Branch
- Navegar para: `Settings -> Branches`.
- Clicar em "Add classic branch protection rule"
- Configurar os bloqueios de branch conforme as configurações do repositório template.
  - Criar bloqueios para as branches:
    - `master`
    - `develop`
    - `release/*`
  - Habilitar as seguintes opções:
    - **Require a pull request before merging**
      - **Require approvals**:
        - Required number of approvals before merging: 1
      - **Require review from Code Owners**
    - **Require status checks to pass before merging**
      - Após o código ser adicionado pelo time de desenvolvimento, incluir o CodeQL como obrigatório.
