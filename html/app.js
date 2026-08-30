const panel = document.getElementById('panel');
const densityRows = document.getElementById('densityRows');

const fmt = (v) => Number(v ?? 0).toFixed(3);
const pct = (v) => `${Math.round(Number(v ?? 0) * 100)}%`;

function row(name, key, data) {
    return `
        <div class="density-row">
            <div class="name">${name}</div>
            <div class="value" title="${fmt(data.base[key])}">${pct(data.base[key])}</div>
            <div class="value" title="${fmt(data.target[key])}">${pct(data.target[key])}</div>
            <div class="value applied" title="${fmt(data.applied[key])}">${pct(data.applied[key])}</div>
        </div>`;
}

window.addEventListener('message', (event) => {
    const msg = event.data || {};

    if (msg.action === 'visible') {
        panel.classList.toggle('hidden', !msg.visible);
        return;
    }

    if (msg.action !== 'update' || !msg.data) return;
    const d = msg.data;
    const ui = d.ui || {};

    document.getElementById('brand').textContent = ui.brand || 'SERVER DEV';
    document.getElementById('title').textContent = ui.title || 'Population Monitor';
    document.getElementById('footer').textContent = `${ui.key || 'F7'} / /${ui.command || 'popdebug'} to hide`;

    document.getElementById('status').textContent = d.enabled ? 'ACTIVE' : 'DISABLED';
    document.getElementById('time').textContent = d.time;
    document.getElementById('profile').textContent = d.profile;
    document.getElementById('zone').textContent = d.zone;
    const areaEl = document.getElementById('area');
    areaEl.textContent = d.zoneMapped === false ? `UNMAPPED → ${d.area}` : d.area;
    areaEl.title = d.zoneMapped === false ? `Fallback area type: ${d.fallbackArea || 'unknown'}` : '';
    areaEl.classList.toggle('warning', d.zoneMapped === false);

    densityRows.innerHTML = row('Peds', 'peds', d) + row('Traffic', 'traffic', d) + row('Parked', 'parked', d);

    document.getElementById('obsPeds').textContent = d.observed.peds;
    document.getElementById('obsVehicles').textContent = d.observed.vehicles;
    document.getElementById('obsParked').textContent = d.observed.parked;
    document.getElementById('radius').textContent = Math.round(d.observed.radius);

    const stats = d.applyStats || { frames: 0, lastTick: 0 };
    const alive = Number(stats.frames || 0) > 0;
    document.getElementById('heartbeat').textContent = alive ? 'RUNNING' : 'STOPPED';
    document.getElementById('frameCount').textContent = `${Number(stats.frames || 0).toLocaleString()} frames`;
});
