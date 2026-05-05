# Checklist de Entrega dos Microsserviços

Para garantir a integração suave com a infraestrutura centralizada do Portal B2B, cada equipe de desenvolvimento de microsserviço deve entregar seu projeto contendo os seguintes requisitos devidamente implementados e documentados em seu próprio repositório.

## Checklist

- [ ] **Nome do Serviço:** Definido conforme o padrão (ex: `produtos-service`).
- [ ] **Porta Oficial:** O serviço deve estar configurado para escutar na porta correta estipulada pela arquitetura (ex: `5002`). A aplicação **deve rodar escutando em `0.0.0.0`** (e não apenas `localhost`/`127.0.0.1`). Exemplo de execução: `uvicorn main:app --host 0.0.0.0 --port 5002`.
- [ ] **Comando para Rodar:** Documentação clara (no README do serviço) informando o comando exato necessário para instalar as dependências e iniciar o microsserviço.
- [ ] **Arquivo `.env.example`:** Deve estar presente na raiz do projeto, contendo as variáveis padrão (ex: `DATABASE_URL`, `DB_SCHEMA`, `KAFKA_BOOTSTRAP_SERVERS`, `PORT`).
- [ ] **Endpoint `/health`:** Um endpoint `GET /health` acessível que retorne status 200 indicando que a aplicação está viva.
- [ ] **Documentação Swagger/OpenAPI:** O serviço deve expor a documentação interativa de suas rotas (geralmente em `/docs`, `/swagger-ui.html` ou similar).
- [ ] **Endpoints REST Funcionais:** Todos os endpoints combinados previamente para as regras de negócio do domínio. Lembrando que a aplicação não precisa expor o prefixo `/api/dominio/` nas suas rotas internas, pois o Nginx Gateway faz essa remoção automática.
- [ ] **Eventos Kafka Publicados:** Se o serviço é produtor, a lógica para publicar no(s) tópico(s) estipulado(s) utilizando o padrão de *Envelope JSON* deve estar funcionando.
- [ ] **Eventos Kafka Consumidos:** Se o serviço é consumidor, o listener do Kafka deve estar escutando corretamente o(s) tópico(s) designados.
- [ ] **Tabelas Utilizadas:** O código não deve criar tabelas (DDL), pois isso é tarefa da Equipe de Banco de Dados. A aplicação (seu ORM/Query Builder) apenas acessa as tabelas já criadas (usando a credencial `svc_portal_b2b` e schema `portal_b2b`). As tabelas do seu domínio devem estar claramente documentadas no seu README.
- [ ] **Dockerfile (Se houver/Recomendado):** Um `Dockerfile` válido caso o serviço seja executado como container, expondo a porta oficial.
