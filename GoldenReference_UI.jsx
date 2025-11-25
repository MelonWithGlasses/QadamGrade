import React, { useState } from 'react';
import { 
  Camera, CheckCircle2, Award, Zap, Sun, MapPin, Share2, RefreshCcw, ShieldCheck, 
  Sparkles, AlertCircle, BookOpen, ChevronRight, XCircle
} from 'lucide-react';

/**
 * QadamGrade Dual Flow Component (Final Integration Ready)
 * ------------------------------
 * ЛОГИКА ВЕТВЛЕНИЯ (BRANCHING LOGIC):
 * 1. Если score === 10: Анимация "Expanding" (Взрыв солнца).
 * 2. Если score < 10: Анимация "Settling" (Солнце уменьшается и улетает вверх).
 */

// --- ASSETS ---
export const OrnamentIcon = ({ className }) => (
  <svg viewBox="0 0 100 100" fill="currentColor" className={className}>
    <path d="M30 50 C 30 20, 70 20, 70 50 C 70 80, 30 80, 30 50 Z M 20 50 C 20 90, 80 90, 80 50 C 80 10, 20 10, 20 50 Z" opacity="0.5" />
    <path d="M10 50 C 10 100, 90 100, 90 50 C 90 0, 10 0, 10 50 Z" opacity="0.3" />
  </svg>
);

export const KazakhSun = ({ className }) => (
  <svg viewBox="0 0 200 200" fill="currentColor" className={className}>
    <circle cx="100" cy="100" r="50" />
    {[...Array(32)].map((_, i) => (
      <g key={i} transform={`rotate(${i * (360 / 32)} 100 100)`}>
        <path d="M100 40 Q 108 30, 100 10 Q 92 30, 100 40" /> 
      </g>
    ))}
  </svg>
);

const QadamGradeDualFlow = () => {
  // Stages: idle -> analyzing -> centering -> (branch point) -> expanding/settling -> result
  const [stage, setStage] = useState('idle');
  const [score, setScore] = useState(0); 
  
  // Состояния для переключателей (Текст/Фото)
  const [taskInputType, setTaskInputType] = useState('text');
  const [answerInputType, setAnswerInputType] = useState('text'); // Добавлено для ответа

  // --- MAIN INTEGRATION POINT ---
  // Эта функция вызывается при нажатии главной кнопки "Тексеру"
  const handleAnalyze = () => {
    if (navigator.vibrate) navigator.vibrate(50);
    setStage('analyzing');

    // =========================================================================
    // TODO: ПОДКЛЮЧЕНИЕ БЭКЕНДА (ИИ)
    // Здесь вы должны сделать запрос к вашему API.
    // Пример логики:
    
    // 1. const response = await api.checkHomework(taskData, answerData);
    // 2. const aiScore = response.score; // Например, 8 или 10
    
    // ДЛЯ ДЕМОНСТРАЦИИ: Я использую случайное число или хардкод.
    // Поменяйте это значение на 10, чтобы увидеть "Взрыв", или на 7, чтобы увидеть "Фидбек".
    const mockServerScore = Math.random() > 0.5 ? 10 : 7; 
    
    // =========================================================================

    setScore(mockServerScore);

    // Тайминг анимации (не меняйте, если не хотите сломать "водоворот")
    setTimeout(() => {
      setStage('centering'); // Спираль
      
      setTimeout(() => {
        // Ветвление анимации на основе оценки
        if (mockServerScore === 10) {
          if (navigator.vibrate) navigator.vibrate([30, 50, 100]); 
          setStage('expanding'); // Сценарий успеха
        } else {
          if (navigator.vibrate) navigator.vibrate(50); 
          setStage('settling'); // Сценарий разбора ошибок
        }

        setTimeout(() => {
          setStage('result'); // Показ UI
        }, 600); 
      }, 800);
    }, 2000);
  };

  const reset = () => {
    setStage('idle');
    setScore(0);
  };

  // Управление Солнцем в зависимости от оценки
  const getSunTransform = () => {
    switch (stage) {
      case 'idle': return 'scale-0 translate-y-20 opacity-0';
      
      // Общая часть
      case 'analyzing': return '-translate-y-20 scale-100 opacity-100'; 
      case 'centering': return 'translate-y-0 scale-75 opacity-100 duration-[800ms] ease-in-out';
      
      // ВЕТВЛЕНИЕ
      case 'expanding': 
        return 'translate-y-0 scale-[200] opacity-100 duration-[1000ms] ease-in-out';
      
      case 'settling': 
      case 'result':
        if (score === 10) {
           return 'translate-y-0 scale-[200] opacity-100'; 
        } else {
           // Улетает вверх, освобождая место для длинного текста
           return '-translate-y-[180px] scale-[0.5] opacity-100 duration-[600ms] cubic-bezier(0.34, 1.56, 0.64, 1)';
        }
        
      default: return 'scale-0';
    }
  };

  return (
    <div className={`relative min-h-screen w-full overflow-hidden font-sans selection:bg-cyan-500 selection:text-white transition-colors duration-1000 ${stage === 'result' && score === 10 ? 'bg-[#FFC629]' : 'bg-slate-900'}`}>
      
      <style>{`
        @keyframes spin { from { transform: rotate(0deg); } to { transform: rotate(360deg); } }
        .animate-spin-fast { animation: spin 3s linear infinite; }
        .animate-spin-slow { animation: spin 12s linear infinite; }
        .glass-card {
          background: rgba(0, 181, 226, 0.05);
          backdrop-filter: blur(20px);
          border: 1px solid rgba(255, 255, 255, 0.1);
          box-shadow: 0 8px 32px 0 rgba(0, 0, 0, 0.3);
        }
        .kazakh-gradient { background: linear-gradient(135deg, #00B5E2 0%, #0088AA 100%); }
      `}</style>

      {/* --- BACKGROUND --- */}
      <div className={`fixed inset-0 pointer-events-none transition-opacity duration-1000 ${stage === 'result' && score === 10 ? 'opacity-0' : 'opacity-100'}`}>
        <div className="absolute top-[-10%] left-[-10%] w-[500px] h-[500px] bg-cyan-600 rounded-full blur-[120px] opacity-20"></div>
        <div className="absolute bottom-[-10%] right-[-10%] w-[500px] h-[500px] bg-amber-500 rounded-full blur-[120px] opacity-10"></div>
        <div className="absolute top-20 right-[-50px] opacity-[0.05] rotate-12"><OrnamentIcon className="w-96 h-96 text-white" /></div>
        <div className="absolute bottom-40 left-[-50px] opacity-[0.05] -rotate-12"><OrnamentIcon className="w-80 h-80 text-white" /></div>
      </div>

      {/* --- SUN CORE --- */}
      <div className={`fixed inset-0 flex items-center justify-center pointer-events-none z-30`}>
        <div className={`relative flex items-center justify-center transition-all duration-500
            ${(stage === 'analyzing' || stage === 'centering') ? 'animate-spin-fast' : ''}
        `}>
          <div className={`absolute flex items-center justify-center text-[#FFC629] drop-shadow-[0_0_30px_rgba(255,198,41,0.6)] w-32 h-32 transition-all ${getSunTransform()}`}>
             <KazakhSun className="w-full h-full" />
             {stage === 'result' && score < 10 && (
               <div className="absolute inset-0 flex items-center justify-center animate-in fade-in zoom-in duration-500">
                 <span className="text-slate-900 font-black text-4xl">{score}</span>
               </div>
             )}
          </div>
        </div>
      </div>

      {/* --- INPUT UI (TASK & ANSWER) --- */}
      <div className={`relative z-20 transition-all duration-700 ease-out ${stage !== 'idle' ? 'opacity-0 scale-90 translate-y-10 pointer-events-none blur-sm' : 'opacity-100 scale-100'}`}>
        <header className="px-6 py-6 flex justify-between items-center">
          <div className="flex flex-col">
            <div className="flex items-center gap-2">
              <ShieldCheck className="text-yellow-400" size={28} />
              <h1 className="text-2xl font-bold tracking-wide text-white drop-shadow-lg">Qadam<span className="text-cyan-400">Grade</span></h1>
            </div>
            <span className="text-[10px] font-medium text-slate-400 tracking-widest uppercase opacity-70 ml-1 mt-1">Made in Kazakhstan</span>
          </div>
          <button className="glass-card w-10 h-10 rounded-full flex items-center justify-center border-yellow-500/20 text-yellow-400 font-bold text-xs">KZ</button>
        </header>

        <main className="px-4 pb-32 max-w-lg mx-auto space-y-5">
          {/* КАРТОЧКА ЗАДАНИЯ */}
          <div className="glass-card rounded-3xl p-6 relative overflow-hidden">
             <div className="absolute left-0 top-0 bottom-0 w-1 bg-gradient-to-b from-cyan-400 to-transparent"></div>
             <div className="flex items-center gap-3 mb-5">
              <div className="p-2 rounded-xl bg-cyan-500/20 text-cyan-300"><CheckCircle2 size={20} /></div>
              <h2 className="text-lg font-semibold text-slate-100">Тапсырма (Задание)</h2>
            </div>
             <div className="flex bg-slate-900/40 p-1 rounded-xl mb-4 border border-white/5">
              <button onClick={() => setTaskInputType('text')} className={`flex-1 py-2.5 rounded-lg text-sm transition-colors ${taskInputType === 'text' ? 'bg-cyan-600 text-white' : 'text-slate-400'}`}>Текст</button>
              <button onClick={() => setTaskInputType('photo')} className={`flex-1 py-2.5 rounded-lg text-sm transition-colors ${taskInputType === 'photo' ? 'bg-cyan-600 text-white' : 'text-slate-400'}`}>Фото</button>
            </div>
            {taskInputType === 'text' ? (
                <textarea className="w-full bg-slate-900/40 rounded-xl border border-white/5 p-4 text-slate-100 min-h-[80px]" placeholder="2 + 2 = ?" defaultValue="2 + 2 = ?" />
            ) : (
                <div className="w-full h-24 bg-slate-900/40 rounded-xl border border-white/5 border-dashed flex items-center justify-center text-slate-500 gap-2">
                    <Camera size={20}/> <span>Сделать фото</span>
                </div>
            )}
          </div>

          {/* КАРТОЧКА ОТВЕТА (Теперь тоже с фото!) */}
          <div className="glass-card rounded-3xl p-6 relative overflow-hidden">
             <div className="absolute left-0 top-0 bottom-0 w-1 bg-gradient-to-b from-yellow-500 to-transparent"></div>
             <div className="flex items-center gap-3 mb-5">
              <div className="p-2 rounded-xl bg-yellow-500/20 text-yellow-300"><Award size={20} /></div>
              <h2 className="text-lg font-semibold text-slate-100">Жауап (Ответ)</h2>
            </div>
            
            {/* Переключатели для ответа */}
            <div className="flex bg-slate-900/40 p-1 rounded-xl mb-4 border border-white/5">
              <button onClick={() => setAnswerInputType('text')} className={`flex-1 py-2.5 rounded-lg text-sm transition-colors ${answerInputType === 'text' ? 'bg-yellow-600 text-white' : 'text-slate-400'}`}>Текст</button>
              <button onClick={() => setAnswerInputType('photo')} className={`flex-1 py-2.5 rounded-lg text-sm transition-colors ${answerInputType === 'photo' ? 'bg-yellow-600 text-white' : 'text-slate-400'}`}>Фото</button>
            </div>

             {answerInputType === 'text' ? (
                <textarea className="w-full bg-slate-900/40 rounded-xl border border-white/5 p-4 text-slate-100 min-h-[80px]" placeholder="Ответ..." defaultValue="5" />
            ) : (
                <div className="w-full h-24 bg-slate-900/40 rounded-xl border border-white/5 border-dashed flex items-center justify-center text-slate-500 gap-2">
                    <Camera size={20}/> <span>Сделать фото</span>
                </div>
            )}
          </div>
        </main>
      </div>

      {/* --- SINGLE MAIN ACTION BUTTON --- */}
      <div className={`fixed bottom-8 left-0 right-0 z-20 flex justify-center px-4 transition-all duration-500 ${stage !== 'idle' ? 'translate-y-40 opacity-0' : 'translate-y-0 opacity-100'}`}>
        <button 
            onClick={handleAnalyze} 
            className="relative w-full max-w-sm flex items-center justify-center gap-3 px-8 py-4 rounded-full kazakh-gradient text-white font-bold text-lg shadow-[0_0_30px_-5px_rgba(0,181,226,0.6)] hover:scale-105 active:scale-95 transition-transform ring-2 ring-white/20"
        >
          <Sparkles className="animate-pulse text-yellow-300" size={20} />
          <span className="tracking-wide">Тексеру (Проверить)</span>
        </button>
      </div>

      {/* --- LOADING TEXT --- */}
      <div className={`fixed inset-0 flex flex-col items-center justify-center z-20 pointer-events-none transition-opacity duration-300 ${(stage === 'analyzing' || stage === 'centering') ? 'opacity-100' : 'opacity-0'}`}>
        <div className="mt-48 text-center">
           <p className="text-2xl font-bold text-white tracking-[0.2em] uppercase animate-pulse">Талдау</p>
           <p className="text-cyan-400 text-sm mt-2">AI Ойлануда...</p>
        </div>
      </div>

      {/* --- RESULT UI: PERFECT (10/10) - С МЕСТОМ ДЛЯ ИИ --- */}
      {score === 10 && (
        <div className={`fixed inset-0 z-40 flex items-center justify-center overflow-y-auto transition-all duration-700 delay-200 ${stage === 'result' ? 'opacity-100 translate-y-0' : 'opacity-0 translate-y-10 pointer-events-none'}`}>
          <div className="w-full max-w-md px-6 min-h-screen flex flex-col pt-10 pb-10">
             {/* Орнамент внутри */}
             <div className="absolute top-0 right-0 opacity-5 pointer-events-none rotate-90"><OrnamentIcon className="w-[500px] h-[500px] text-black" /></div>
            
            <div className="flex flex-col items-center text-slate-900 mb-6">
                <div className="relative mb-4">
                <div className="w-24 h-24 bg-white rounded-full flex items-center justify-center shadow-2xl animate-[bounce_1s_infinite]">
                    <span className="text-4xl font-black">10</span>
                </div>
                <div className="absolute -bottom-2 -right-2 bg-black text-white px-3 py-1 rounded-full text-xs font-bold">MAX</div>
                </div>
                <h2 className="text-3xl font-black uppercase tracking-tighter mb-1">Өте жақсы!</h2>
                <p className="font-medium opacity-70">Мінсіз жауап (Идеально)</p>
            </div>

            {/* ПРОСТРАНСТВО ДЛЯ ИИ (10/10) */}
            <div className="bg-white/60 backdrop-blur-xl rounded-[24px] p-6 shadow-xl border border-white/40 flex-1 overflow-y-auto max-h-[50vh]">
                <div className="flex items-center gap-2 mb-4 text-slate-800">
                    <Sparkles size={18} className="text-yellow-600" />
                    <span className="font-bold uppercase tracking-wider text-sm">AI Комментарий:</span>
                </div>
                <p className="text-slate-800 leading-relaxed text-sm">
                    {/* Placeholder для длинного текста */}
                    Это блестящее решение! Ученик не только дал правильный ответ, но и продемонстрировал глубокое понимание темы. <br/><br/>
                    1. Ход решения логичен и последователен.<br/>
                    2. Арифметика безупречна.<br/>
                    3. Формулировка ответа четкая.<br/><br/>
                    Так держать! Рекомендую переходить к более сложным задачам на умножение.
                </p>
            </div>

            <button onClick={reset} className="w-full py-4 rounded-2xl bg-slate-900 text-white font-bold shadow-xl mt-4">Жаңа есеп</button>
          </div>
        </div>
      )}

      {/* --- RESULT UI: IMPERFECT (< 10) - С МЕСТОМ ДЛЯ ИИ --- */}
      {score < 10 && (
        <div className={`fixed inset-0 z-40 flex flex-col items-center justify-end sm:justify-center overflow-hidden transition-all duration-500 delay-300 ${stage === 'result' ? 'opacity-100 translate-y-0' : 'opacity-0 translate-y-10 pointer-events-none'}`}>
          
          <div className="w-full max-w-md h-[85vh] sm:h-[80vh] flex flex-col">
            
            <div className="glass-card bg-slate-900/95 rounded-t-[32px] sm:rounded-[32px] p-0 border-t border-white/10 shadow-2xl relative flex flex-col h-full overflow-hidden">
               {/* Светящийся эффект */}
               <div className="absolute top-0 left-1/2 -translate-x-1/2 w-32 h-1 bg-gradient-to-r from-transparent via-cyan-400 to-transparent opacity-50 z-10"></div>

               {/* Заголовок */}
               <div className="pt-10 pb-6 text-center shrink-0 relative z-10 bg-gradient-to-b from-slate-900/90 to-transparent">
                 <h2 className="text-2xl font-bold text-white mb-1">Жақсы, бірақ...</h2>
                 <p className="text-slate-400 text-sm">Есть над чем поработать</p>
               </div>

               {/* СКРОЛЛЯЩАЯСЯ ОБЛАСТЬ ДЛЯ ИИ */}
               <div className="flex-1 overflow-y-auto px-6 pb-4 space-y-6">
                   
                   {/* Блок 1: Ошибки (Подробный разбор) */}
                   <div>
                        <div className="flex items-center gap-2 mb-3 text-red-400 sticky top-0 bg-slate-900/95 py-2 z-10 backdrop-blur-sm">
                            <AlertCircle size={18} />
                            <span className="font-bold text-sm uppercase tracking-wide">Қателер (Разбор)</span>
                        </div>
                        <div className="bg-red-500/5 border border-red-500/20 rounded-2xl p-5">
                            <p className="text-slate-300 text-sm leading-relaxed mb-3">
                                Ученик допустил ошибку в вычислениях. В примере "2 + 2" он получил "5", что является неверным.
                            </p>
                            <ul className="space-y-3">
                                <li className="flex gap-3 text-slate-300 text-sm bg-red-500/10 p-3 rounded-lg">
                                    <XCircle size={16} className="text-red-400 shrink-0 mt-0.5" />
                                    <span>
                                        <strong className="text-red-300">Арифметика:</strong> Нарушена логика сложения простых чисел. Возможно, ученик поторопился или перепутал цифры.
                                    </span>
                                </li>
                            </ul>
                        </div>
                   </div>

                   {/* Блок 2: Советы (Подробно) */}
                   <div>
                        <div className="flex items-center gap-2 mb-3 text-cyan-400 sticky top-0 bg-slate-900/95 py-2 z-10 backdrop-blur-sm">
                            <BookOpen size={18} />
                            <span className="font-bold text-sm uppercase tracking-wide">AI Ұсыныстар (Советы)</span>
                        </div>
                        <div className="bg-cyan-500/5 border border-cyan-500/20 rounded-2xl p-5">
                            <p className="text-slate-300 text-sm leading-relaxed mb-4">
                                Для улучшения результата рекомендую повторить базовую таблицу сложения. Вот конкретные шаги:
                            </p>
                            <ul className="space-y-3">
                                <li className="flex gap-3 text-slate-300 text-sm">
                                    <div className="w-1.5 h-1.5 rounded-full bg-cyan-400 mt-1.5 shrink-0"></div>
                                    <span>Использовать счетные палочки или пальцы для визуализации.</span>
                                </li>
                                <li className="flex gap-3 text-slate-300 text-sm">
                                    <div className="w-1.5 h-1.5 rounded-full bg-cyan-400 mt-1.5 shrink-0"></div>
                                    <span>Решить 5 похожих примеров для закрепления материала.</span>
                                </li>
                                <li className="flex gap-3 text-slate-300 text-sm">
                                    <div className="w-1.5 h-1.5 rounded-full bg-cyan-400 mt-1.5 shrink-0"></div>
                                    <span>Обратить внимание на аккуратность записи цифры "4".</span>
                                </li>
                            </ul>
                        </div>
                   </div>

               </div>

               {/* Footer Button */}
               <div className="p-6 pt-2 shrink-0 bg-gradient-to-t from-slate-900 to-transparent">
                    <button onClick={reset} className="w-full py-4 rounded-2xl bg-white text-slate-900 font-bold shadow-lg hover:bg-slate-200 transition-colors flex items-center justify-center gap-2">
                        <RefreshCcw size={18} /> Қайта көру
                    </button>
               </div>
            </div>
          </div>
        </div>
      )}

    </div>
  );
};

export default QadamGradeDualFlow;