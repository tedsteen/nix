const homeView = document.querySelector("#home-view");
const detailView = document.querySelector("#detail-view");
const addDialog = document.querySelector("#add-dialog");
const addForm = document.querySelector("#transaction-form");
const editDialog = document.querySelector("#edit-dialog");
const editForm = document.querySelector("#edit-form");
const message = document.querySelector("#message");
const editMessage = document.querySelector("#edit-message");
const recentComments = document.querySelector("#recent-comments");
const actionButtons = document.querySelectorAll("[data-action]");
const editActionButtons = document.querySelectorAll("[data-edit-action]");
const pageSize = 20;
const durationControllers = new Map();

let appState = { balances: { Finn: 0, Milo: 0 }, history: [] };
let selectedKid;
let currentPage = 1;
let action = "add";
let editAction = "add";
let editingId;
let recentTransactions = new Map();

function formatDuration(totalMinutes) {
  const hours = Math.floor(Math.abs(totalMinutes) / 60);
  const minutes = Math.abs(totalMinutes) % 60;
  if (hours && minutes) return `${hours}h ${minutes}m`;
  if (hours) return `${hours}h`;
  return `${minutes}m`;
}

document.querySelectorAll("[data-duration-wheel]").forEach((wheel) => {
  const form = wheel.closest("form");
  const input = form.elements.duration;
  let selectedIndex = 0;
  let animationFrame;

  const options = Array.from({ length: 97 }, (_, index) => {
    const option = document.createElement("button");
    option.type = "button";
    option.className = "duration-option";
    option.dataset.minutes = index * 15;
    option.textContent = formatDuration(index * 15);
    option.addEventListener("click", () => setDuration(index * 15, true));
    return option;
  });
  wheel.replaceChildren(...options);

  function selectIndex(index) {
    selectedIndex = Math.max(0, Math.min(options.length - 1, index));
    const minutes = selectedIndex * 15;
    input.value = minutes;
    wheel.setAttribute("aria-valuenow", minutes);
    wheel.setAttribute("aria-valuetext", formatDuration(minutes));
    options.forEach((option, optionIndex) =>
      option.classList.toggle("selected", optionIndex === selectedIndex),
    );
  }

  function setDuration(minutes, smooth = false) {
    const index = Math.round(Number(minutes) / 15);
    selectIndex(index);
    wheel.scrollTo({ top: selectedIndex * 52, behavior: smooth ? "smooth" : "auto" });
  }

  wheel.addEventListener("scroll", () => {
    cancelAnimationFrame(animationFrame);
    animationFrame = requestAnimationFrame(() => selectIndex(Math.round(wheel.scrollTop / 52)));
  });
  wheel.addEventListener("keydown", (event) => {
    if (!["ArrowUp", "ArrowDown"].includes(event.key)) return;
    event.preventDefault();
    setDuration((selectedIndex + (event.key === "ArrowDown" ? 1 : -1)) * 15, true);
  });

  selectIndex(0);
  durationControllers.set(form, { setDuration });
});

function toLocalDateTime(timestamp) {
  const date = new Date(`${timestamp.replace(" ", "T")}Z`);
  const offset = date.getTimezoneOffset() * 60_000;
  return new Date(date.getTime() - offset).toISOString().slice(0, 16);
}

function transactionRow(transaction) {
  const row = document.createElement("article");
  row.className = "history-row";

  const details = document.createElement("div");
  const comment = document.createElement("span");
  comment.className = "history-comment";
  comment.textContent = transaction.comment;
  const date = document.createElement("time");
  const timestamp = `${transaction.createdAt.replace(" ", "T")}Z`;
  date.dateTime = timestamp;
  date.textContent = new Intl.DateTimeFormat(undefined, {
    dateStyle: "medium",
    timeStyle: "short",
  }).format(new Date(timestamp));
  details.append(comment, date);

  const amount = document.createElement("div");
  amount.className = `amount ${transaction.minutes > 0 ? "positive" : "negative"}`;
  amount.textContent = `${transaction.minutes > 0 ? "+" : "−"}${formatDuration(transaction.minutes)}`;

  const edit = document.createElement("button");
  edit.className = "edit";
  edit.type = "button";
  edit.textContent = "Edit";
  edit.setAttribute("aria-label", `Edit ${transaction.comment} transaction`);
  edit.addEventListener("click", () => openEditor(transaction));

  const remove = document.createElement("button");
  remove.className = "remove";
  remove.type = "button";
  remove.textContent = "Remove";
  remove.setAttribute("aria-label", `Remove ${transaction.comment} transaction`);
  remove.addEventListener("click", () => removeTransaction(transaction));

  const links = document.createElement("div");
  links.className = "history-links";
  links.append(edit, remove);
  const actions = document.createElement("div");
  actions.className = "history-actions";
  actions.append(amount, links);
  row.append(details, actions);
  return row;
}

function renderDetail() {
  if (!selectedKid) return;

  document.querySelector("#detail-kid").textContent = selectedKid;
  document.querySelector("#detail-balance").textContent = formatDuration(
    appState.balances[selectedKid],
  );

  const kidHistory = appState.history.filter((transaction) => transaction.child === selectedKid);
  const pageCount = Math.max(1, Math.ceil(kidHistory.length / pageSize));
  currentPage = Math.min(currentPage, pageCount);
  const pageHistory = kidHistory.slice((currentPage - 1) * pageSize, currentPage * pageSize);
  const container = document.querySelector("#detail-history");

  if (pageHistory.length === 0) {
    container.innerHTML = `<div class="empty">No transactions yet.</div>`;
  } else {
    container.replaceChildren(...pageHistory.map(transactionRow));
  }

  document.querySelector("#page-status").textContent = `Page ${currentPage} of ${pageCount}`;
  document.querySelector("#previous-page").disabled = currentPage === 1;
  document.querySelector("#next-page").disabled = currentPage === pageCount;
  document.querySelector(".pagination").hidden = kidHistory.length <= pageSize;
}

function render(state) {
  appState = state;
  for (const [kid, minutes] of Object.entries(state.balances)) {
    document.querySelector(`#${kid}-balance`).textContent = formatDuration(minutes);
  }
  renderDetail();
}

function showKid(kid) {
  selectedKid = kid;
  currentPage = 1;
  homeView.hidden = true;
  detailView.hidden = false;
  renderDetail();
  window.scrollTo({ top: 0, behavior: "auto" });
}

document.querySelectorAll("[data-kid]").forEach((card) => {
  card.addEventListener("click", () => showKid(card.dataset.kid));
});

document.querySelector(".back").addEventListener("click", () => {
  selectedKid = undefined;
  detailView.hidden = true;
  homeView.hidden = false;
});

document.querySelector("#previous-page").addEventListener("click", () => {
  currentPage -= 1;
  renderDetail();
});
document.querySelector("#next-page").addEventListener("click", () => {
  currentPage += 1;
  renderDetail();
});

function setAction(nextAction) {
  action = nextAction;
  actionButtons.forEach((button) =>
    button.classList.toggle("active", button.dataset.action === nextAction),
  );
  addForm.querySelector(".submit").textContent =
    action === "add" ? "Add to bank" : "Use screen time";
  addDialog.classList.toggle("spending", action === "spend");
  message.textContent = "";
}

actionButtons.forEach((button) => {
  button.addEventListener("click", () => setAction(button.dataset.action));
});

function updateRecentComments() {
  recentTransactions = new Map();
  for (const transaction of appState.history) {
    if (transaction.child === selectedKid && !recentTransactions.has(transaction.comment)) {
      recentTransactions.set(transaction.comment, transaction);
    }
    if (recentTransactions.size === 10) break;
  }

  recentComments.replaceChildren(
    ...[...recentTransactions.values()].map((transaction) => {
      const option = document.createElement("option");
      option.value = transaction.comment;
      option.label = `${transaction.minutes > 0 ? "Add" : "Use"} · ${formatDuration(transaction.minutes)}`;
      return option;
    }),
  );
}

addForm.elements.comment.addEventListener("input", (event) => {
  const transaction = recentTransactions.get(event.target.value);
  if (!transaction) return;
  setAction(transaction.minutes > 0 ? "add" : "spend");
  durationControllers.get(addForm).setDuration(Math.abs(transaction.minutes), true);
});

document.querySelector(".add-entry").addEventListener("click", () => {
  addForm.reset();
  setAction("add");
  document.querySelector("#add-kid").textContent = selectedKid;
  addForm.querySelector(".date-details").open = false;
  message.textContent = "";
  updateRecentComments();
  addDialog.showModal();
  durationControllers.get(addForm).setDuration(0);
});

function closeDialog(dialog) {
  dialog.close();
}

document.querySelector("#add-dialog .close").addEventListener("click", () => closeDialog(addDialog));
document.querySelector("#edit-dialog .close").addEventListener("click", () => closeDialog(editDialog));
for (const dialog of [addDialog, editDialog]) {
  dialog.addEventListener("click", (event) => {
    if (event.target === dialog) dialog.close();
  });
}

function setEditAction(nextAction) {
  editAction = nextAction;
  editActionButtons.forEach((button) =>
    button.classList.toggle("active", button.dataset.editAction === nextAction),
  );
}

editActionButtons.forEach((button) => {
  button.addEventListener("click", () => setEditAction(button.dataset.editAction));
});

function openEditor(transaction) {
  editingId = transaction.id;
  editForm.elements.comment.value = transaction.comment;
  editForm.elements.createdAt.value = toLocalDateTime(transaction.createdAt);
  editMessage.textContent = "";
  setEditAction(transaction.minutes > 0 ? "add" : "spend");
  editDialog.showModal();
  durationControllers.get(editForm).setDuration(Math.abs(transaction.minutes));
}

async function removeTransaction(transaction) {
  if (!window.confirm(`Remove “${transaction.comment}” from ${selectedKid}'s history?`)) return;

  try {
    const response = await fetch(`/api/transactions/${transaction.id}`, { method: "DELETE" });
    const result = await response.json();
    if (!response.ok) throw new Error(result.error);
    render(result);
  } catch (error) {
    window.alert(error.message);
  }
}

editForm.addEventListener("submit", async (event) => {
  event.preventDefault();
  editMessage.textContent = "";
  const saveButton = editForm.querySelector(".submit");
  const data = new FormData(editForm);
  const duration = Number(data.get("duration"));

  if (!Number.isInteger(duration) || duration <= 0) {
    editMessage.textContent = "Choose at least 15 minutes.";
    return;
  }

  saveButton.disabled = true;
  try {
    const response = await fetch(`/api/transactions/${editingId}`, {
      method: "PUT",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({
        minutes: editAction === "add" ? duration : -duration,
        comment: data.get("comment"),
        createdAt: new Date(data.get("createdAt")).toISOString(),
      }),
    });
    const result = await response.json();
    if (!response.ok) throw new Error(result.error);
    render(result);
    editDialog.close();
  } catch (error) {
    editMessage.textContent = error.message;
  } finally {
    saveButton.disabled = false;
  }
});

addForm.addEventListener("submit", async (event) => {
  event.preventDefault();
  message.textContent = "";
  const submitButton = addForm.querySelector(".submit");
  const data = new FormData(addForm);
  const duration = Number(data.get("duration"));

  if (!Number.isInteger(duration) || duration <= 0) {
    message.textContent = "Choose at least 15 minutes.";
    return;
  }

  submitButton.disabled = true;
  try {
    const response = await fetch("/api/transactions", {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({
        child: selectedKid,
        minutes: action === "add" ? duration : -duration,
        comment: data.get("comment"),
        createdAt: data.get("createdAt")
          ? new Date(data.get("createdAt")).toISOString()
          : undefined,
      }),
    });
    const result = await response.json();
    if (!response.ok) throw new Error(result.error);
    currentPage = 1;
    render(result);
    addDialog.close();
  } catch (error) {
    message.textContent = error.message;
  } finally {
    submitButton.disabled = false;
  }
});

async function loadState() {
  const response = await fetch("/api/state");
  if (!response.ok) throw new Error("Could not load the bank.");
  render(await response.json());
}

loadState().catch((error) => {
  document.querySelector("header > p:last-child").textContent = error.message;
});
