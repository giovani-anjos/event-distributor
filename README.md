# Event Distributor

## Cenário
Considere um fluxo onde diversas aplicações emitem eventos como resultado do seu
processamento. Um pipeline é responsável por consumir estes eventos e
disponibilizá-los, de tempos em tempos, como arquivos em um diretório.
**Payload de exemplo de um evento salvo:**
```
{
    "event_id": "3aaafb1f-c83b-4e77-9d0a-8d88f9a9fa9a",
    "timestamp": "2021-01-14T10:18:57",
    "domain": "account",
    "event_type": "status-change",
    "data": {
        "id": 948874,
        "old_status": "SUSPENDED",
        "new_status": "ACTIVE",
        "reason": "Natus nam ad minima consequatur temporibus."
    }
}
```
## Considerações
- Todos os eventos respeitam um contrato base, contendo os campos
**event_id**, **timestamp**, **domain**, **event_type** e **data**:
- O campo **event_id** representa um identificador único de cada evento;
- O campo **timestamp** representa a data/hora de geração do evento;
- A combinação dos campos **domain** + **event_type** representam um
único tipo de evento;
- O campo **data** corresponde ao payload do evento e seu formato é livre,
a ser definido por cada aplicação que o produz;
- Dentro do objeto data existe um campo **id** que representa o identificador
único da entidade, conforme exemplos abaixo:
    - Quando o domain for igual a **account**, representa o identificador
de uma conta;
    - Quando o domain for igual a **transaction**, representa o
identificador de uma transação;
- Existem tipos diferentes de eventos (combinação **domain** + **event_type**)
misturados nos arquivos;
- Existe a possibilidade de existirem eventos duplicados nos arquivos;

## O desafio
Dado o contexto acima, queremos que você desenvolva uma solução capaz de
consumir um conjunto de arquivos contendo uma amostra de eventos e separá-los
em diretórios distintos por cada tipo evento.

## Solução
A solução deste desafio encontra-se documentada no seguinte link: [Solution](https://github.com/giovani-anjos/event-distributor/blob/main/solution.pdf)