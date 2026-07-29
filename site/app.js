const money = new Intl.NumberFormat("en-US", {
  style: "currency",
  currency: "USD",
  maximumFractionDigits: 2,
});

function text(id, value) {
  const node = document.getElementById(id);
  if (node) node.textContent = value ?? "—";
}

function record(title, body, meta = "") {
  const article = document.createElement("article");
  article.className = "record";
  const heading = document.createElement("h3");
  heading.textContent = title;
  const paragraph = document.createElement("p");
  paragraph.textContent = body;
  article.append(heading, paragraph);
  if (meta) {
    const small = document.createElement("small");
    small.textContent = meta;
    article.append(small);
  }
  return article;
}

function renderMoney(events, entities) {
  const target = document.getElementById("money-events");
  target.replaceChildren();
  for (const event of events) {
    const article = document.createElement("article");
    article.className = "flow-event";

    const kind = document.createElement("div");
    kind.innerHTML = `<span class="badge">${event.event_type.replaceAll("_", " ")}</span>`;

    const narrative = document.createElement("div");
    const source = entities.get(event.source_entity)?.canonical_name ?? event.source_entity;
    const recipient = entities.get(event.recipient_entity)?.canonical_name ?? event.recipient_entity;
    const path = document.createElement("p");
    path.innerHTML = `<strong>${source}</strong> → <strong>${recipient}</strong>`;
    const program = document.createElement("p");
    program.textContent = event.program;
    const note = document.createElement("small");
    note.textContent = `${event.fiscal_year} · ${event.verification_status} · ${event.interpretation_note}`;
    narrative.append(path, program, note);

    const amount = document.createElement("div");
    amount.className = "amount";
    amount.textContent = money.format(Number(event.amount));

    article.append(kind, narrative, amount);
    target.append(article);
  }
}

async function start() {
  try {
    const response = await fetch("./data/case.json", { cache: "no-store" });
    if (!response.ok) throw new Error(`public data returned ${response.status}`);
    const data = await response.json();
    const currentCase = data.case;

    text("case-notice", data.release_state.notice);
    text("case-title-heading", currentCase.title);
    text("case-status", currentCase.status);
    text("jurisdiction", currentCase.jurisdiction);
    text("operating-focus", currentCase.operating_focus);
    text("primary-period", currentCase.primary_period);
    text("publication-authority", currentCase.publication_authority);
    text("mission-question", currentCase.mission_question);
    text("source-count", data.sources.length);
    text("entity-count", data.entities.length);
    text("event-count", data.money_events.length);
    text("claim-count", data.claims.length);

    const entityTarget = document.getElementById("entities");
    const entityMap = new Map();
    for (const entity of data.entities) {
      entityMap.set(entity.entity_id, entity);
      entityTarget.append(
        record(
          entity.canonical_name,
          `${entity.entity_type} · ${entity.jurisdiction}`,
          `Identity: ${entity.match_status} · ${entity.resolution_method}`,
        ),
      );
    }

    const sourceTarget = document.getElementById("sources");
    for (const source of data.sources) {
      const item = record(
        source.title,
        `${source.publisher} · ${source.source_type}`,
        source.limitations.join(" "),
      );
      const link = document.createElement("a");
      link.href = source.source_url;
      link.target = "_blank";
      link.rel = "noreferrer";
      link.textContent = "Open source record";
      item.append(link);
      sourceTarget.append(item);
    }

    renderMoney(data.money_events, entityMap);
  } catch (error) {
    const main = document.getElementById("main");
    const failure = document.createElement("p");
    failure.className = "error";
    failure.textContent = `The public evidence bundle could not be loaded: ${error.message}`;
    main.prepend(failure);
  }
}

start();
