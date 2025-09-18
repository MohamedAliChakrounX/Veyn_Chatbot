import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';

export interface AskResponse {
  question: string;
  answer: string;
  source: 'cache' | 'agent';
}

@Injectable({
  providedIn: 'root'
})
export class ChatService {
  private baseUrl = 'http://localhost:8000';

  constructor(private http: HttpClient) { }

  askQuestion(question: string, sessionId: string): Observable<AskResponse> {
    return this.http.post<AskResponse>(`${this.baseUrl}/ask`, {
      session_id: sessionId,  // Utiliser l'ID de session spécifique
      question: question
    });
  }
}