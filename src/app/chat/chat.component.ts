import { Component, AfterViewChecked, ElementRef, ViewChild } from '@angular/core';
import { ChatService } from '../../services/chat.service';

interface ChatMessage {
  sender: 'user' | 'bot';
  message: string;
  source?: string;
  time: Date;
}

interface ChatSession {
  id: string;
  title: string;
  lastMessageTime: Date;
  messages: ChatMessage[];
}

@Component({
  selector: 'app-chat',
  templateUrl: './chat.component.html',
  styleUrls: ['./chat.component.css']
})
export class ChatComponent implements AfterViewChecked {
  @ViewChild('chatContainer') private chatContainer!: ElementRef;
  @ViewChild('textarea') private textarea!: ElementRef;

  question = '';
  loading = false;
  error: string | null = null;
  chatHistory: ChatMessage[] = [];
  chatSessions: ChatSession[] = [];
  currentSessionId: string = '';

  constructor(private chatService: ChatService) {
    this.initializeSessions();
  }

  initializeSessions(): void {
    // Charger les sessions depuis le localStorage
    const savedSessions = localStorage.getItem('chatSessions');
    if (savedSessions) {
      try {
        const parsedSessions = JSON.parse(savedSessions);
        // Convertir les dates string en objets Date
        this.chatSessions = parsedSessions.map((session: any) => ({
          ...session,
          lastMessageTime: new Date(session.lastMessageTime),
          messages: session.messages.map((msg: any) => ({
            ...msg,
            time: new Date(msg.time)
          }))
        }));
      } catch (e) {
        console.error('Erreur lors du parsing des sessions:', e);
        this.chatSessions = [];
      }
    }

    // Si aucune session, créer une nouvelle session
    if (this.chatSessions.length === 0) {
      this.newChat();
    } else {
      // Charger la première session (la plus récente)
      this.loadSession(this.chatSessions[0].id);
    }
  }



  loadSession(sessionId: string): void {
    const session = this.chatSessions.find(s => s.id === sessionId);
    if (session) {
      this.currentSessionId = sessionId;
      this.chatHistory = [...session.messages];
      this.scrollToBottom();
    }
  }

  deleteSession(sessionId: string, event: Event): void {
    event.stopPropagation(); // Empêche le chargement de la session lors du clic sur la poubelle

    const index = this.chatSessions.findIndex(s => s.id === sessionId);
    if (index !== -1) {
      this.chatSessions.splice(index, 1);
      this.saveSessions();

      // Si on supprime la session active
      if (sessionId === this.currentSessionId) {
        if (this.chatSessions.length > 0) {
          // Charger la première session disponible
          this.loadSession(this.chatSessions[0].id);
        } else {
          // Créer une nouvelle session si plus aucune session existe
          this.newChat();
        }
      }
    }
  }

  saveSessions(): void {
    // Mettre à jour la session actuelle
    const currentSession = this.chatSessions.find(s => s.id === this.currentSessionId);
    if (currentSession) {
      currentSession.messages = [...this.chatHistory];
      currentSession.lastMessageTime = new Date();

      // Mettre à jour le titre si c'est la première question
      if (this.chatHistory.length > 0) {
        const firstUserMessage = this.chatHistory.find(msg => msg.sender === 'user');
        if (firstUserMessage) {
          currentSession.title = firstUserMessage.message.length > 30
            ? firstUserMessage.message.substring(0, 30) + '...'
            : firstUserMessage.message;
        }
      }
    }

    // Sauvegarder dans le localStorage
    localStorage.setItem('chatSessions', JSON.stringify(this.chatSessions));
  }

  onInput(event: Event): void {
    const element = event.target as HTMLDivElement;
    this.question = element.innerText || '';
    this.adjustTextareaHeight();
  }

  onPaste(event: ClipboardEvent): void {
    event.preventDefault();
    const text = event.clipboardData?.getData('text/plain') || '';
    document.execCommand('insertText', false, text);
    this.question = text;
    this.adjustTextareaHeight();
  }

  onEnter(event: KeyboardEvent): void {
    if (event.key === 'Enter' && !event.shiftKey) {
      event.preventDefault();
      this.sendQuestion();
    }
  }

  // Modifier la méthode sendQuestion()
  sendQuestion(): void {
    const trimmedQuestion = this.question.trim();
    if (!trimmedQuestion || this.loading) return;

    // Ajouter la question utilisateur
    const userMessage: ChatMessage = {
      sender: 'user',
      message: trimmedQuestion,
      time: new Date()
    };
    this.addMessage(userMessage);

    this.loading = true;
    this.error = null;
    this.question = '';
    this.resetTextarea();

    // Appel au service avec le session_id spécifique
    this.chatService.askQuestion(trimmedQuestion, this.currentSessionId).subscribe({
      next: (res) => {
        const botMessage: ChatMessage = {
          sender: 'bot',
          message: res.answer,
          source: res.source || 'Conseils Voyage',
          time: new Date()
        };
        this.addMessage(botMessage);
        this.loading = false;
        this.saveSessions();
      },
      error: (err) => {
        this.error = err.error?.detail || 'Une erreur est survenue lors de la recherche. Veuillez réessayer.';
        this.loading = false;
        this.saveSessions();
      }
    });
  }

  // Modifier la méthode newChat() pour générer de nouveaux IDs
  newChat(): void {
    const newSessionId = Date.now().toString() + '-' + Math.random().toString(36).substr(2, 9);

    const newSession: ChatSession = {
      id: newSessionId,
      title: 'Nouvelle discussion',
      lastMessageTime: new Date(),
      messages: []
    };

    this.chatSessions.unshift(newSession);
    this.currentSessionId = newSessionId;
    this.chatHistory = [];
    this.saveSessions();
  }

  private scrollToBottomIfNeeded(): void {
    try {
      const container = this.chatContainer.nativeElement;
      const threshold = 50; // tolérance en px
      const isNearBottom =
        container.scrollHeight - container.scrollTop - container.clientHeight < threshold;

      if (isNearBottom) {
        setTimeout(() => {
          container.scrollTop = container.scrollHeight;
        }, 0);
      }
    } catch (err) {
      console.error('Erreur lors du défilement :', err);
    }
  }


  private addMessage(message: ChatMessage): void {
    this.chatHistory = [...this.chatHistory, message];
    this.scrollToBottomIfNeeded();  // nouveau
  }

  adjustTextareaHeight(): void {
    const textarea = this.textarea.nativeElement;
    textarea.style.height = 'auto';
    textarea.style.height = `${Math.min(textarea.scrollHeight, 150)}px`;
  }

  resetTextarea(): void {
    if (this.textarea?.nativeElement) {
      this.textarea.nativeElement.innerText = '';
      this.textarea.nativeElement.style.height = 'auto';
    }
  }

  ngAfterViewChecked(): void {

  }

  private scrollToBottom(): void {
    try {
      setTimeout(() => {
        this.chatContainer.nativeElement.scrollTop = this.chatContainer.nativeElement.scrollHeight;
      }, 0);
    } catch (err) {
      console.error('Erreur lors du défilement :', err);
    }
  }
  clearAllSessions(): void {
    localStorage.removeItem('chatSessions');  // supprime du stockage
    this.chatSessions = [];                   // vide la liste en mémoire
    this.newChat();                           // recrée une session vide
  }

  suggestedQuestions: string[] = [
    "Les points d'arrêts entre Jufra et Tripoli",
    "Les dates et les horaires disponibles pour un voyage de Tripoli à Tunis",
    "Le prix d'un voyage de Tripoli à Tunis",
    "Combien de places je peux réserver à la fois",
    "Combien de réduction pour un enfant de moins de six ans"
  ];

  sendSuggestedQuestion(question: string): void {
    this.question = question;
    this.sendQuestion();
  }


}