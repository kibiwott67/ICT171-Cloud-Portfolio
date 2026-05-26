/**
 * main.js — MedCare interactive features
 * ICT171 Assignment 3 — Allan Kibiwott
 */

// ── HAMBURGER MENU ──────────────────────────────────────
const hamburger = document.getElementById('hamburger');
const navLinks  = document.querySelector('.nav-links');
if (hamburger && navLinks) {
  hamburger.addEventListener('click', () => navLinks.classList.toggle('open'));
}

// ── HEALTH TIPS ROTATOR ─────────────────────────────────
const TIPS = [
  "Drink at least 8 glasses of water daily. Proper hydration improves energy levels, concentration, and skin health.",
  "Aim for 7–9 hours of sleep per night. Consistent sleep reduces risk of cardiovascular disease and improves immune function.",
  "30 minutes of moderate exercise, 5 days a week, reduces all-cause mortality by up to 35%.",
  "Eat 5 servings of fruit and vegetables daily — a simple habit linked to significantly lower cancer and heart disease risk.",
  "Wash your hands for at least 20 seconds to prevent the spread of 80% of common infectious diseases.",
  "Limit added sugar to under 25g (6 teaspoons) per day to reduce risk of type 2 diabetes and obesity.",
  "Stand up and move for at least 2 minutes every hour if you have a desk job. Prolonged sitting is an independent risk factor.",
  "Regular sunscreen use (SPF 30+) reduces skin cancer risk by 40–50%.",
  "Social connection is as important to health as exercise. Isolation raises mortality risk similarly to smoking 15 cigarettes a day.",
  "Deep breathing exercises for just 5 minutes can reduce blood pressure and cortisol levels measurably.",
];

let tipIndex = 0;
const tipText = document.getElementById('tip-text');

function newTip() {
  if (!tipText) return;
  tipIndex = (tipIndex + 1) % TIPS.length;
  tipText.style.opacity = '0';
  setTimeout(() => {
    tipText.textContent = TIPS[tipIndex];
    tipText.style.opacity = '1';
  }, 300);
}

if (tipText) {
  tipText.style.transition = 'opacity 0.3s';
  tipText.textContent = TIPS[Math.floor(Math.random() * TIPS.length)];
}

// ── BMI CALCULATOR ──────────────────────────────────────
function calcBMI() {
  const weight = parseFloat(document.getElementById('weight')?.value);
  const height = parseFloat(document.getElementById('height')?.value);
  const result = document.getElementById('bmi-result');
  if (!result) return;

  if (!weight || !height || weight <= 0 || height <= 0) {
    result.style.display = 'block';
    result.style.background = 'rgba(220,38,38,0.2)';
    result.style.color = '#fff';
    result.textContent = 'Please enter valid weight and height values.';
    return;
  }

  const heightM = height / 100;
  const bmi = (weight / (heightM * heightM)).toFixed(1);
  let category, colour;

  if      (bmi < 18.5) { category = 'Underweight';     colour = 'rgba(234,179,8,0.25)'; }
  else if (bmi < 25)   { category = 'Healthy Weight';  colour = 'rgba(34,197,94,0.25)'; }
  else if (bmi < 30)   { category = 'Overweight';      colour = 'rgba(234,179,8,0.25)'; }
  else                 { category = 'Obese';            colour = 'rgba(220,38,38,0.25)'; }

  result.style.display = 'block';
  result.style.background = colour;
  result.style.color = '#fff';
  result.innerHTML = `BMI: <strong>${bmi}</strong> — ${category}<br><small style="font-weight:400;opacity:0.85;">WHO classification based on weight and height provided.</small>`;
}

// ── HEALTH TIPS FILTER ──────────────────────────────────
function filterTips(category, btn) {
  // Update active tab
  document.querySelectorAll('.tab-btn').forEach(b => b.classList.remove('active'));
  btn.classList.add('active');

  // Show/hide articles
  document.querySelectorAll('.tip-article').forEach(article => {
    if (category === 'all' || article.dataset.category === category) {
      article.classList.remove('hidden');
    } else {
      article.classList.add('hidden');
    }
  });
}
